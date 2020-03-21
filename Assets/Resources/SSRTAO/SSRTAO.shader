Shader "Hidden/SSRTAO"
{
    CGINCLUDE
        #pragma target 3.0
    ENDCG

    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        // 0: Occlusion estimation
        Pass
        {
            CGPROGRAM
            #pragma vertex CommonVert
            #pragma fragment frag
            #pragma multi_compile RAYTRACING_QUALITY_LOW RAYTRACING_QUALITY_MID RAYTRACING_QUALITY_HIGH
            #include "SSRTAO_Utils.cginc"

            float4 frag (VertOut input) : SV_Target
            {
                // Reconstruct view pos and normal.
                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, input.uv);
                float4 devicePos = float4(input.uv.x * 2.0 - 1.0, input.uv.y * 2.0 - 1.0, depth, 1.0);
                float4 viewPos = mul(_invProjMatrix, devicePos);
                viewPos /= viewPos.w;
                float3 viewNorm = DecodeViewNormalStereo(tex2D(_CameraDepthNormalsTexture, input.uv));

                // Discard the background pixels.
                if(depth == 0) return 0.0f;

                // Load the ray directions from the blue noise texture.
                #if RAYTRACING_QUALITY_LOW
                const uint nRays = 4u;
                #elif RAYTRACING_QUALITY_MID
                const uint nRays = 16u;
                #elif RAYTRACING_QUALITY_HIGH
                const uint nRays = 32u;
                #endif
                float3 ray0  = getSamplingRay(viewNorm, input.pos.xy, 0);
                float3 ray1  = getSamplingRay(viewNorm, input.pos.xy, 1);
                float3 ray2  = getSamplingRay(viewNorm, input.pos.xy, 2);
                float3 ray3  = getSamplingRay(viewNorm, input.pos.xy, 3);
                #if RAYTRACING_QUALITY_MID | RAYTRACING_QUALITY_HIGH
                float3 ray4  = getSamplingRay(viewNorm, input.pos.xy, 4);
                float3 ray5  = getSamplingRay(viewNorm, input.pos.xy, 5);
                float3 ray6  = getSamplingRay(viewNorm, input.pos.xy, 6);
                float3 ray7  = getSamplingRay(viewNorm, input.pos.xy, 7);
                float3 ray8  = getSamplingRay(viewNorm, input.pos.xy, 8);
                float3 ray9  = getSamplingRay(viewNorm, input.pos.xy, 9);
                float3 ray10 = getSamplingRay(viewNorm, input.pos.xy, 10);
                float3 ray11 = getSamplingRay(viewNorm, input.pos.xy, 11);
                float3 ray12 = getSamplingRay(viewNorm, input.pos.xy, 12);
                float3 ray13 = getSamplingRay(viewNorm, input.pos.xy, 13);
                float3 ray14 = getSamplingRay(viewNorm, input.pos.xy, 14);
                float3 ray15 = getSamplingRay(viewNorm, input.pos.xy, 15);
                #endif
                #if RAYTRACING_QUALITY_HIGH
                float3 ray16 = getSamplingRay(viewNorm, input.pos.xy, 16);
                float3 ray17 = getSamplingRay(viewNorm, input.pos.xy, 17);
                float3 ray18 = getSamplingRay(viewNorm, input.pos.xy, 18);
                float3 ray19 = getSamplingRay(viewNorm, input.pos.xy, 19);
                float3 ray20 = getSamplingRay(viewNorm, input.pos.xy, 20);
                float3 ray21 = getSamplingRay(viewNorm, input.pos.xy, 21);
                float3 ray22 = getSamplingRay(viewNorm, input.pos.xy, 22);
                float3 ray23 = getSamplingRay(viewNorm, input.pos.xy, 23);
                float3 ray24 = getSamplingRay(viewNorm, input.pos.xy, 24);
                float3 ray25 = getSamplingRay(viewNorm, input.pos.xy, 25);
                float3 ray26 = getSamplingRay(viewNorm, input.pos.xy, 26);
                float3 ray27 = getSamplingRay(viewNorm, input.pos.xy, 27);
                float3 ray28 = getSamplingRay(viewNorm, input.pos.xy, 28);
                float3 ray29 = getSamplingRay(viewNorm, input.pos.xy, 29);
                float3 ray30 = getSamplingRay(viewNorm, input.pos.xy, 30);
                float3 ray31 = getSamplingRay(viewNorm, input.pos.xy, 31);
                #endif

                #if RAYTRACING_QUALITY_LOW
                float occSum = getRayOcclusion(viewPos,ray0) + getRayOcclusion(viewPos,ray1) + 
                               getRayOcclusion(viewPos,ray2) + getRayOcclusion(viewPos,ray3);
                #elif RAYTRACING_QUALITY_MID
                float occSum = getRayOcclusion(viewPos,ray0) + getRayOcclusion(viewPos,ray1) + 
                               getRayOcclusion(viewPos,ray2) + getRayOcclusion(viewPos,ray3) +
                               getRayOcclusion(viewPos,ray4) + getRayOcclusion(viewPos,ray5) +
                               getRayOcclusion(viewPos,ray6) + getRayOcclusion(viewPos,ray7) +
                               getRayOcclusion(viewPos,ray8) + getRayOcclusion(viewPos,ray9) +
                               getRayOcclusion(viewPos,ray10) + getRayOcclusion(viewPos,ray11) +
                               getRayOcclusion(viewPos,ray12) + getRayOcclusion(viewPos,ray13) +
                               getRayOcclusion(viewPos,ray14) + getRayOcclusion(viewPos,ray15);
                #elif RAYTRACING_QUALITY_HIGH
                float occSum = getRayOcclusion(viewPos,ray0) + getRayOcclusion(viewPos,ray1) + 
                               getRayOcclusion(viewPos,ray2) + getRayOcclusion(viewPos,ray3) +
                               getRayOcclusion(viewPos,ray4) + getRayOcclusion(viewPos,ray5) +
                               getRayOcclusion(viewPos,ray6) + getRayOcclusion(viewPos,ray7) +
                               getRayOcclusion(viewPos,ray8) + getRayOcclusion(viewPos,ray9) +
                               getRayOcclusion(viewPos,ray10) + getRayOcclusion(viewPos,ray11) +
                               getRayOcclusion(viewPos,ray12) + getRayOcclusion(viewPos,ray13) +
                               getRayOcclusion(viewPos,ray14) + getRayOcclusion(viewPos,ray15) + 
                               getRayOcclusion(viewPos,ray16) + getRayOcclusion(viewPos,ray17) +
                               getRayOcclusion(viewPos,ray18) + getRayOcclusion(viewPos,ray19) +
                               getRayOcclusion(viewPos,ray20) + getRayOcclusion(viewPos,ray21) +
                               getRayOcclusion(viewPos,ray22) + getRayOcclusion(viewPos,ray23) +
                               getRayOcclusion(viewPos,ray24) + getRayOcclusion(viewPos,ray25) +
                               getRayOcclusion(viewPos,ray26) + getRayOcclusion(viewPos,ray27) +
                               getRayOcclusion(viewPos,ray28) + getRayOcclusion(viewPos,ray29) +
                               getRayOcclusion(viewPos,ray30) + getRayOcclusion(viewPos,ray31);
                #endif
                float occ = 1.0f - occSum / nRays;
                return float4(pow(occ * _intensity, 0.6), viewNorm * 0.5 + 0.5);
            }
            ENDCG
        }

        // 1: Upscale + Horizontal Blur Filter
        Pass
        {
            CGPROGRAM
            #pragma vertex CommonVert
            #pragma fragment frag
            #include "SSRTAO_Utils.cginc"

            // Normal vector comparer (for geometry-aware weighting)
            half CompareNormal(half3 d1, half3 d2)
            {
                return smoothstep(0.8, 1.0, dot(d1, d2));
            }

            float4 frag (VertOut input) : SV_Target
            {
                float2 delta = float2(_MainTex_TexelSize.x * 2.0, 0.0);

                // Fater 5-tap Gaussian with linear sampling
                fixed4 p0  = tex2D(_MainTex, input.uvSPR);
                fixed4 p1a = tex2D(_MainTex, input.uvSPR - delta * 1.3846153846);
                fixed4 p1b = tex2D(_MainTex, input.uvSPR + delta * 1.3846153846);
                fixed4 p2a = tex2D(_MainTex, input.uvSPR - delta * 3.2307692308);
                fixed4 p2b = tex2D(_MainTex, input.uvSPR + delta * 3.2307692308);

                fixed3 n0 = DecodeViewNormalStereo(tex2D(_CameraDepthNormalsTexture, input.uvSPR));

                half w0  = 0.2270270270;
                half w1a = CompareNormal(n0, p1a.gba * 2.0f - 1.0f) * 0.3162162162;
                half w1b = CompareNormal(n0, p1b.gba * 2.0f - 1.0f) * 0.3162162162;
                half w2a = CompareNormal(n0, p2a.gba * 2.0f - 1.0f) * 0.0702702703;
                half w2b = CompareNormal(n0, p2b.gba * 2.0f - 1.0f) * 0.0702702703;

                half s;
                s  = p0.r  * w0;
                s += p1a.r * w1a;
                s += p1b.r * w1b;
                s += p2a.r * w2a;
                s += p2b.r * w2b;

                s /= w0 + w1a + w1b + w2a + w2b;

                return float4(s, n0 * 0.5 + 0.5);
            }
            ENDCG
        }

        // 2: Vertical Blur Filter
        Pass
        {
            CGPROGRAM
            #pragma vertex CommonVert
            #pragma fragment frag
            #include "SSRTAO_Utils.cginc"

            // Normal vector comparer (for geometry-aware weighting)
            half CompareNormal(half3 d1, half3 d2)
            {
                return smoothstep(0.8, 1.0, dot(d1, d2));
            }

            float4 frag (VertOut input) : SV_Target
            {
                float2 delta = float2(0.0, _MainTex_TexelSize.y * 2.0);

                // Fater 5-tap Gaussian with linear sampling
                fixed4 p0  = tex2D(_MainTex, input.uvSPR);
                fixed4 p1a = tex2D(_MainTex, input.uvSPR - delta * 1.3846153846);
                fixed4 p1b = tex2D(_MainTex, input.uvSPR + delta * 1.3846153846);
                fixed4 p2a = tex2D(_MainTex, input.uvSPR - delta * 3.2307692308);
                fixed4 p2b = tex2D(_MainTex, input.uvSPR + delta * 3.2307692308);

                fixed3 n0 = p0.gba * 2.0 - 1.0;

                half w0  = 0.2270270270;
                half w1a = CompareNormal(n0, p1a.gba * 2.0f - 1.0f) * 0.3162162162;
                half w1b = CompareNormal(n0, p1b.gba * 2.0f - 1.0f) * 0.3162162162;
                half w2a = CompareNormal(n0, p2a.gba * 2.0f - 1.0f) * 0.0702702703;
                half w2b = CompareNormal(n0, p2b.gba * 2.0f - 1.0f) * 0.0702702703;

                half s;
                s  = p0.r  * w0;
                s += p1a.r * w1a;
                s += p1b.r * w1b;
                s += p2a.r * w2a;
                s += p2b.r * w2b;

                s /= w0 + w1a + w1b + w2a + w2b;

                return float4(s, n0 * 0.5 + 0.5);
            }
            ENDCG
        }

        // 3: Temporal reset
        Pass
        {
            CGPROGRAM
            #pragma vertex CommonVert
            #pragma fragment frag
            #include "SSRTAO_Utils.cginc"

            float2 frag (VertOut input) : SV_Target
            {
                return float2(tex2D(_MainTex, input.uv.xy).r, 1.0f);
            }
            ENDCG
        }

        // 4: Temporal filter
        Pass
        {
            CGPROGRAM
            #pragma vertex CommonVert
            #pragma fragment frag
            #include "SSRTAO_Utils.cginc"

            float2 GetClosestFragment(float2 uv)
            {
                const float2 k = float2(1.0f, 1.0f) / _ScreenParams.xy;
                const float4 neighborhood = float4(
                    SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv - k),
                    SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv + float2(k.x, -k.y)),
                    SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv + float2(-k.x, k.y)),
                    SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv + k)
                    );

            #if defined(UNITY_REVERSED_Z)
                #define COMPARE_DEPTH(a, b) step(b, a)
            #else
                #define COMPARE_DEPTH(a, b) step(a, b)
            #endif

                float3 result = float3(0.0, 0.0, SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv));
                result = lerp(result, float3(-1.0, -1.0, neighborhood.x), COMPARE_DEPTH(neighborhood.x, result.z));
                result = lerp(result, float3( 1.0, -1.0, neighborhood.y), COMPARE_DEPTH(neighborhood.y, result.z));
                result = lerp(result, float3(-1.0,  1.0, neighborhood.z), COMPARE_DEPTH(neighborhood.z, result.z));
                result = lerp(result, float3( 1.0,  1.0, neighborhood.w), COMPARE_DEPTH(neighborhood.w, result.z));

                return (uv + result.xy * k);
            }

            // Adapted from Playdead's TAA implementation
            // https://github.com/playdeadgames/temporal
            float2 ClipToAABB(float2 color, float p, float minimum, float maximum)
            {
                // note: only clips towards aabb center (but fast!)
                float center  = 0.5 * (maximum + minimum);
                float extents = 0.5 * (maximum - minimum);

                // This is actually `distance`, however the keyword is reserved
                float2 offset = color - float2(center, p);
                float repeat = abs(offset.x / extents);

                if (repeat > 1.0)
                {
                    // `color` is not intersecting (nor inside) the AABB; it's clipped to the closest extent
                    return float2(center, p) + offset / repeat;
                }
                else
                {
                    // `color` is intersecting (or inside) the AABB.

                    // Note: for whatever reason moving this return statement from this else into a higher
                    // scope makes the NVIDIA drivers go beyond bonkers
                    return color;
                }
            }

            float2 frag (VertOut input) : SV_Target
            {
                // Get the dilated motion vectors.
                float2 motion = tex2D(_CameraMotionVectorsTexture, GetClosestFragment(input.uv.xy)).xy;

                const float2 k = _MainTex_TexelSize.xy;
                float2 uv = input.uv.xy;

                float color = tex2D(_MainTex, uv).x;
                float topLeft = tex2D(_MainTex, uv - k * 0.5).x;
                float bottomRight = tex2D(_MainTex, uv + k * 0.5).x;
                float corners = 4.0 * (topLeft + bottomRight) - 2.0 * color;
                float average = (corners + color) * 0.142857;

                float2 luma = float2(average.x, color.x);
                float nudge = 4.0 * abs(luma.x - luma.y);
                float minimum = min(bottomRight, topLeft) - nudge;
                float maximum = max(topLeft, bottomRight) + nudge;

                float2 history = tex2D(_HistoryTex, input.uv.xy - motion).xy;

                // Clip history samples
                history = ClipToAABB(history, history.y, minimum, maximum);

                // Store fragment motion history
                float2 finalColor = float2(color, saturate(smoothstep(0.002 * _MainTex_TexelSize.z, 0.0035 * _MainTex_TexelSize.z, length(motion))));

                // Blend method
                float weight = clamp(lerp(0.95, 0.85,
                    length(motion) * 6e03), 0.85, 0.95);

                finalColor = lerp(finalColor, history, weight);

                float2 results = finalColor;
                results.y *= 0.85;

                return results;
            }
            ENDCG
        }

        // 5: Final Composition
        Pass
        {
            CGPROGRAM
            #pragma vertex CommonVert
            #pragma fragment frag
            #pragma shader_feature DEBUG
            #include "SSRTAO_Utils.cginc"

            float4 frag (VertOut input) : SV_Target
            {
                float ao = 1.0f - tex2D(_AOTex, input.uv).r;
                #if defined(DEBUG)
                return ao;
                #else
                return ao * tex2D(_MainTex, input.uv);
                #endif
            }
            ENDCG
        }
    }
}
