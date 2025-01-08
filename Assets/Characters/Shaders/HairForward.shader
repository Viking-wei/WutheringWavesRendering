Shader "WutheringWave/HairForward"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NormalMap ("NormalMap", 2D) = "bump" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "UnityPBSLighting.cginc"

            half LightingDiffuse(half3 lightDir, half3 normal, half atten)
            {
                half diff = dot(lightDir, normal);
                diff = diff * 0.5 + 0.5;
                //diff = max(0, diff);
                return diff * atten;
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
            sampler2D _NormalMap;
            float4 _MainTex_ST;

            
            
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

            fixed4 frag (v2f i) : SV_Target
            {
                float3 normal = normalize(mul(unity_ObjectToWorld,i.normal));
                float3 tangent = normalize(mul(unity_ObjectToWorld,i.tangent));
                float3 bitangent = cross(normal, tangent);
                float3x3 tbn = float3x3(tangent, bitangent, normal);
                
                // sample the texture 
                fixed4 col = tex2D(_MainTex, i.uv);
                half4 packedNormal = tex2D(_NormalMap, i.uv);
                half3 normalTS = UnpackNormal(packedNormal);
                half3 normalWS = mul(normalTS, tbn);
                float3 lightDir = _WorldSpaceLightPos0.xyz;
                half diffuse = LightingDiffuse(lightDir, normalWS, 1);
                UNITY_APPLY_FOG(i.fogCoord, col);
                
                return col * diffuse;
                return half4(normalWS,1);
            }
            ENDCG
        }
    }
}
