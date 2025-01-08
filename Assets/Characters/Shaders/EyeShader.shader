Shader "WutheringWave/EyeShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SpecFlipBook ("SpecFlipBook", 2D) = "white" {}
        _FlipIndex ("FlipIndex", Range(0,15)) = 0
        _SecondSpec ("SecondSpec", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
// Upgrade NOTE: excluded shader from OpenGL ES 2.0 because it uses non-square matrices
#pragma exclude_renderers gles
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            float2 FlipbookUV(float2 uv, float width, float height, float tile)
            {
                tile = floor((tile + 0.00001) % (width * height));
                float2 index = float2(floor(tile % width), height - 1 - floor(tile / width));
                return (uv + index) / float2(width, height);
            }

            float2 SimpleParallax(float2 uv, float height, float3 viewDir, float scale)
            {
                viewDir = normalize(viewDir);
                float2 vec = viewDir.xy ;
                float2 offset = vec * height * scale;
                return uv + offset * float2(1, -1);
            }

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 color : COLOR;
                float3 normal : NORMAL;
                float3 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 color : TEXCOORD1;
                float3 positionWS : TEXCOORD2;
                float3 normal : TEXCOORD3;
                float3 tangent : TEXCOORD4;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _SpecFlipBook;
            sampler2D _SecondSpec;
            float4 _MainTex_ST;
            float _FlipIndex;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.positionWS = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.color = v.color;
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.tangent = UnityObjectToWorldDir(v.tangent);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                float3 normal = normalize(i.normal);
                float3 tangent = normalize(i.tangent);
                float3 bitangent = cross(normal, tangent);
                float3x3 tbn = float3x3(tangent, bitangent, normal);
                
                float height = tex2D(_SpecFlipBook, i.uv).g;
                float3 viewDirWS = normalize(_WorldSpaceCameraPos.xyz - i.positionWS);
                float3 viewDirTS = mul(tbn, viewDirWS);
                float2 parallaxUV = SimpleParallax(i.uv, height, viewDirTS, 0.02);
                
                half4 baseColor = tex2D(_MainTex, parallaxUV);
                
                float flipSpec = 0.3 * tex2D(_SpecFlipBook, FlipbookUV(parallaxUV, 4, 4, _FlipIndex)).b;
                float firstSpec = 0.4 * tex2D(_SpecFlipBook, parallaxUV).r;
                float secondSpec = tex2D(_SecondSpec, parallaxUV).r;
                float spec = firstSpec + flipSpec;
                
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return baseColor + spec;
            }
            ENDCG
        }
    }
}
