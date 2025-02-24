Shader "WutheringWave/ClothShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Ramp ("Texture", 2D) = "white" {}
        _NormalMap ("NormalMap", 2D) = "bump" {}
        _MatCapTex ("MatCapTex", 2D) = "white" {}
        _Shininess ("Shininess", Range(0.1, 100.0)) = 32.0
        _OutlineTex ("OutlineTex", 2D) = "Black" {}
        _OutlineWidth ("Outline Width", Range(0.01, 1)) = 0.01
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
            sampler2D _MatCapTex;
            sampler2D _Ramp;
            float _Shininess;
            float4 _MainTex_ST;
            
            half LightingDiffuse(half3 lightDir, half3 normal, half atten)
            {
                half diff = max(dot(lightDir, normal),0.0);
                return diff * atten;
            }

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

                half4 packedNormal = tex2D(_NormalMap, i.uv);
                half3 normalTS = UnpackNormal(packedNormal);
                half3 normalWS = mul(normalTS, tbn);

                float3 lightDir = _WorldSpaceLightPos0.xyz;
                half diffuse = LightingDiffuse(lightDir, normalWS, 1);
                
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.positionWS);
                float3 halfVec = normalize(lightDir + viewDir);
                float specReal = pow(max(dot(normalWS, halfVec), 0.0), _Shininess);

                // environment lighting
                half3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;
                

                float3 viewNormal = normalize(mul((float3x3)unity_MatrixV,normalWS));
                float matcapUV = 0.5 + 0.5 * viewNormal.xy;
                half4 matcapColor = tex2D(_MatCapTex, matcapUV);
                float2 matcapMask = tex2D(_NormalMap, i.uv).ba;
                // sample the texture
                half4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                //return half4(ambient,1);
                return diffuse+specReal;
                return col + matcapColor * matcapMask.x;
            }
            ENDCG
        }

        Pass
        {
            Tags {"LightMode"="ForwardBase"}
            Name "Outline"
            Cull Front
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #include "UnityCG.cginc"

            float _OutlineWidth;
            sampler2D _OutlineTex;

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
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                float4 vextex = v.vertex + float4(normalize(v.tangent), 0) * _OutlineWidth*0.01;
                o.vertex = UnityObjectToClipPos(vextex);
                o.uv = v.uv;
                o.color = v.color;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }
            

            half4 frag (v2f i) : SV_Target
            {
                half4 col = tex2D(_OutlineTex, i.uv);
                return col;
            }
            ENDCG
        }
    }
}
