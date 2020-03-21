#ifndef SSRTAO_CG_INCLUDED
#define SSRTAO_CG_INCLUDED

    #include "UnityCG.cginc"

    // -----------------------------------------------------------------------------
    // Global Uniforms

    sampler2D _MainTex;
    float4 _MainTex_TexelSize;
    float4 _MainTex_ST;

    // -----------------------------------------------------------------------------
    // Vertex shaders

    struct VertAttrs
    {
        float4 vertex : POSITION;
        float4 texcoord : TEXCOORD0;
    };

    struct VertOut
    {
        float4 pos : SV_POSITION;
        half2 uv : TEXCOORD0;    // Original UV
        half2 uv01 : TEXCOORD1;  // Alternative UV (supports v-flip case)
        half2 uvSPR : TEXCOORD2; // Single pass stereo rendering UV
    };

    VertOut CommonVert(VertAttrs v)
    {
        half2 uvAlt = v.texcoord.xy;

    #if UNITY_UV_STARTS_AT_TOP
        if (_MainTex_TexelSize.y < 0.0) uvAlt.y = 1.0 - uvAlt.y;
    #endif

        VertOut o;
        o.pos = UnityObjectToClipPos(v.vertex);
        o.uv = v.texcoord.xy;
        o.uv01 = uvAlt;
        o.uvSPR = UnityStereoTransformScreenSpaceTex(uvAlt);

        return o;
    }

    // -----------------------------------------------------------------------------
    // Frag Uniforms
	
    #define DEPTH_ERROR 0.0000001f

    sampler2D _CameraGBufferTexture2;
    sampler2D_float _CameraDepthTexture;
    sampler2D _CameraDepthNormalsTexture;
    sampler2D _CameraMotionVectorsTexture;

    sampler2D _HistoryTex;
    sampler2D _AOTex;

    Texture2DArray _samplingDirTexArray;
    uint _samplingDirTexArrayOffset;
    uint4 _samplingDirTexDimensions;

    float _samplingRadius;
    float _influenceRadius;
    float _intensity;

    float4x4 _projMatrix;
    float4x4 _invProjMatrix;

    // -----------------------------------------------------------------------------
    // Frag Utility Functions

    float3 getSamplingRay(const float3 hemisphereNormal, const uint2 clipPos, const uint idx) 
    {
        float3 dir = _samplingDirTexArray.Load(uint4(clipPos, _samplingDirTexArrayOffset + idx, 0) % _samplingDirTexDimensions) * 2.0 - 1.0;
        return sign(dot(hemisphereNormal, dir)) * dir;
    }

    float getStepOcclusion(const float4 viewOrigin, const float3 viewStep)
    {
        float4 viewPos = viewOrigin + float4(viewStep, 0.0f);
        float4 devicePos = mul(_projMatrix, viewPos);
        devicePos /= devicePos.w;

        float sampledDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, devicePos.xy * 0.5 + 0.5);
        float occlusion = saturate(sign(devicePos.z - sampledDepth + DEPTH_ERROR));

        float depthDiff = abs(viewOrigin.z + LinearEyeDepth(sampledDepth));
        return saturate(occlusion + depthDiff / (_samplingRadius + _influenceRadius));
    }

    float getRayOcclusion(const float4 rayPos, const float3 rayDir)
    {
        float rayOcclusion = 1.0f;
        #if RAYTRACING_QUALITY_LOW
        const float stepSize = _samplingRadius / 2.0f;
        rayOcclusion *= getStepOcclusion(rayPos, rayDir * stepSize * 1.0f);
        rayOcclusion *= getStepOcclusion(rayPos, rayDir * stepSize * 2.0f);
        #elif RAYTRACING_QUALITY_MID
        const float stepSize = _samplingRadius / 4.0f;
        rayOcclusion *= getStepOcclusion(rayPos, rayDir * stepSize * 1.0f);
        rayOcclusion *= getStepOcclusion(rayPos, rayDir * stepSize * 2.0f);
        rayOcclusion *= getStepOcclusion(rayPos, rayDir * stepSize * 3.0f);
        rayOcclusion *= getStepOcclusion(rayPos, rayDir * stepSize * 4.0f);
        #elif RAYTRACING_QUALITY_HIGH
        const float stepSize = _samplingRadius / 8.0f;
        rayOcclusion *= getStepOcclusion(rayPos, rayDir * stepSize * 1.0f);
        rayOcclusion *= getStepOcclusion(rayPos, rayDir * stepSize * 2.0f);
        rayOcclusion *= getStepOcclusion(rayPos, rayDir * stepSize * 3.0f);
        rayOcclusion *= getStepOcclusion(rayPos, rayDir * stepSize * 4.0f);
        rayOcclusion *= getStepOcclusion(rayPos, rayDir * stepSize * 5.0f);
        rayOcclusion *= getStepOcclusion(rayPos, rayDir * stepSize * 6.0f);
        rayOcclusion *= getStepOcclusion(rayPos, rayDir * stepSize * 7.0f);
        rayOcclusion *= getStepOcclusion(rayPos, rayDir * stepSize * 8.0f);
        #endif
        return rayOcclusion;
    }

    // -----------------------------------------------------------------------------
    // Frag Functions

#endif // SSRTAO_CG_INCLUDED
