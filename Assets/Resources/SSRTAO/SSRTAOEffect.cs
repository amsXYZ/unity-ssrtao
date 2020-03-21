using UnityEngine;

[RequireComponent(typeof(Camera)), ExecuteInEditMode]
public class SSRTAOEffect : MonoBehaviour
{
    private const int kNoiseTexWidth = 64;
    private const int kNoiseTexHeight = 64;
    private const int kNoiseTexCount = 64;

    private enum Quality { Low, Mid, High };
    private uint QualityCount = 3;
    private string[] QualityKeywords = { "RAYTRACING_QUALITY_LOW", "RAYTRACING_QUALITY_MID", "RAYTRACING_QUALITY_HIGH" };
    private uint[] QualitySampleCount = { 4, 16, 32 };

    [SerializeField]
    private Quality quality = Quality.Low;
    [SerializeField]
    private bool downsample = false;
    [SerializeField]
    private bool debug = false;
    [SerializeField, Range(0.01f, 8.0f)]
    private float samplingRadius = 0.3f;
    [SerializeField, Range(0.0f, 4.0f)]
    private float influenceRadius = 1.0f;
    [SerializeField, Range(0.0f, 4.0f)]
    private float intensity = 1.0f;

    private Material mMaterial;
    private Camera mCamera;
    private Texture2DArray mNoiseTexArray;
    private RenderTexture mHistoryRT;
    private bool mResetHistory;

    // Sets/Remove the necessary variables for rendering
    void SetupRenderingParams()
    {
        // Create the material
        mMaterial = new Material(Shader.Find("Hidden/SSRTAO"));
        mMaterial.SetVector("_samplingDirTexDimensions", new Vector2(kNoiseTexWidth, kNoiseTexHeight));

        // Get Camera
        mCamera = GetComponent<Camera>();
        mCamera.depthTextureMode = DepthTextureMode.Depth | DepthTextureMode.DepthNormals | DepthTextureMode.MotionVectors;

        // Create the blue noise texture array.
        mNoiseTexArray = new Texture2DArray(kNoiseTexWidth, kNoiseTexHeight, kNoiseTexCount, TextureFormat.RGB24, false, true);
        mNoiseTexArray.filterMode = FilterMode.Point;
        mNoiseTexArray.wrapMode = TextureWrapMode.Repeat;
        for (int i = 0; i < kNoiseTexCount; i++)
        {
            Texture2D tex = Resources.Load<Texture2D>("SSRTAO/BlueNoise_RGB_64/LDR_RGB1_" + i);
            mNoiseTexArray.SetPixels(tex.GetPixels(), i);
        }
        mNoiseTexArray.Apply();

        // Create the history RT.
        mHistoryRT = new RenderTexture(mCamera.pixelWidth, mCamera.pixelHeight, 0, RenderTextureFormat.RG16, RenderTextureReadWrite.Linear);
        mResetHistory = true;
    }

    void ClearRenderingParams()
    {
        if (mMaterial) { DestroyImmediate(mMaterial); mMaterial = null; }
        if (mNoiseTexArray) { DestroyImmediate(mNoiseTexArray); mNoiseTexArray = null; }
        if (mHistoryRT) { DestroyImmediate(mHistoryRT); mHistoryRT = null; mResetHistory = false; }
    }

    void OnEnable()
    {
        SetupRenderingParams();
    }

    void OnDisable()
    {
        ClearRenderingParams();
    }

    // Called by the camera to apply the image effect
    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        // Get some temporary resources needed for performing the screen passes.
        RenderTexture occRT;
        if(downsample) occRT = RenderTexture.GetTemporary(mCamera.pixelWidth / 2, mCamera.pixelHeight / 2, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);
        else occRT = RenderTexture.GetTemporary(mCamera.pixelWidth, mCamera.pixelHeight, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);
        RenderTexture intOccRT = RenderTexture.GetTemporary(mCamera.pixelWidth, mCamera.pixelHeight, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);
        RenderTexture filteredOccRT = RenderTexture.GetTemporary(mCamera.pixelWidth, mCamera.pixelHeight, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);
        RenderTexture temportalOccRT = RenderTexture.GetTemporary(mCamera.pixelWidth, mCamera.pixelHeight, 0, RenderTextureFormat.RG16, RenderTextureReadWrite.Linear);

        // Enable/Disable the appropiate macros.
        for (uint i = 0; i < QualityCount; i++)
        {
            if (i == (uint)quality) mMaterial.EnableKeyword(QualityKeywords[i]);
            else mMaterial.DisableKeyword(QualityKeywords[i]);
        }
        if (debug) mMaterial.EnableKeyword("DEBUG");
        else mMaterial.DisableKeyword("DEBUG");

        // Perform any needed state changes.
        Matrix4x4 projMat = GL.GetGPUProjectionMatrix(mCamera.projectionMatrix, false);
        mMaterial.SetMatrix("_projMatrix", projMat);
        mMaterial.SetMatrix("_invProjMatrix", projMat.inverse);

        mMaterial.SetTexture("_samplingDirTexArray", mNoiseTexArray);
        mMaterial.SetInt("_samplingDirTexArrayOffset", (int)(Time.frameCount * QualitySampleCount[(uint)quality]) % mNoiseTexArray.depth);
        mMaterial.SetVector("_samplingDirTexDimensions", new Vector4(mNoiseTexArray.width, mNoiseTexArray.height, mNoiseTexArray.depth, 1.0f));
        mMaterial.SetFloat("_samplingRadius", samplingRadius);
        mMaterial.SetFloat("_influenceRadius", influenceRadius);

        mMaterial.SetFloat("_intensity", intensity);
        mMaterial.SetTexture("_HistoryTex", mHistoryRT);
        mMaterial.SetTexture("_AOTex", temportalOccRT);

        // Perform the SSRTAO pass.
        Graphics.Blit(source, occRT, mMaterial, 0);

        // Filter/Upscale the results.
        Graphics.Blit(occRT, intOccRT, mMaterial, 1);
        Graphics.Blit(intOccRT, filteredOccRT, mMaterial, 2);

        // Apply the temporal filter (and store the results for next frame).
        if (mResetHistory)
        {
            Graphics.Blit(filteredOccRT, mHistoryRT, mMaterial, 3);
            mResetHistory = false;
        }
        Graphics.Blit(filteredOccRT, temportalOccRT, mMaterial, 4);
        Graphics.Blit(temportalOccRT, mHistoryRT);

        // Compose the final image.
        Graphics.Blit(source, destination, mMaterial, 5);

        // Release temporary resources
        RenderTexture.ReleaseTemporary(occRT);
        RenderTexture.ReleaseTemporary(intOccRT);
        RenderTexture.ReleaseTemporary(filteredOccRT);
        RenderTexture.ReleaseTemporary(temportalOccRT);
    }
}