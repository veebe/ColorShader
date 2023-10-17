Shader "Custom/ColorOnlyShader"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _Color("Color", Color) = (1, 1, 1, 1)
        _AlphaThreshold("Alpha Threshold", Range(0, 1)) = 0.5
    }
        SubShader
        {
            Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" }
            LOD 200

            Pass
            {
                Blend SrcAlpha OneMinusSrcAlpha

                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #include "UnityCG.cginc"

                struct appdata
                {
                    float4 vertex : POSITION;
                    float2 uv : TEXCOORD0;
                };

                struct v2f
                {
                    float2 uv : TEXCOORD0;
                    float4 vertex : SV_POSITION;
                };

                sampler2D _MainTex;
                float4 _MainTex_ST;
                fixed4 _Color;
                float _AlphaThreshold;

                float3 RGBToHSV(float3 c)
                {
                    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
                    float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
                    float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
                    float d = q.x - min(q.w, q.y);
                    float e = 1.0e-10;
                    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
                }

                float3 HSVToRGB(float3 c)
                {
                    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
                    float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
                    return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
                }

                v2f vert(appdata v)
                {
                    v2f o;
                    o.vertex = UnityObjectToClipPos(v.vertex);
                    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                    return o;
                }

                fixed4 frag(v2f i) : SV_Target
                {
                    fixed4 texColor = tex2D(_MainTex, i.uv);

                    if (texColor.a > _AlphaThreshold)
                    {
                        fixed4 outputColor = _Color;
                        outputColor.a = texColor.a;

                        float3 OGColorHSV = RGBToHSV(texColor.rgb);
                        float3 ColorHSV = RGBToHSV(outputColor.rgb);

                        if(OGColorHSV.z >= 0.8){
                            float finalSat = OGColorHSV.z - 0.8;
                            finalSat *= 5;
                            ColorHSV = float3(ColorHSV.x, (46 - 46 * finalSat) / 100, 1);
                        }
                        else if (OGColorHSV.z < 0.8 && OGColorHSV.z > 0.24)  {
                            float finalSat = OGColorHSV.z - 0.25;
                            finalSat = finalSat * 1.85;
                            float finalLum = OGColorHSV.z - 0.25;
                            finalLum = finalLum * 1.85;
                            ColorHSV = float3(ColorHSV.x, (99 - finalSat * 53) / 100, (47 + finalLum * 53) / 100);
                        }
                        else if (OGColorHSV.z < 0.25) {
                            float finalLum = OGColorHSV.z;
                            finalLum = finalLum * 4;
                            ColorHSV = float3(ColorHSV.x, 1, (finalLum * 47) / 100);
                        }
                        float3 colorRGB = HSVToRGB(ColorHSV);

                        outputColor.rgb = colorRGB;
                        return outputColor;
                    }
                    else
                    {
                        return texColor;
                    }
                }

                ENDCG
            }
        }
}