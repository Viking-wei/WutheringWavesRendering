Shader "WutheringWave/Skin"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NormalMap ("NormalMap", 2D) = "bump" {}
        _MatCapTex ("MatCapTex", 2D) = "Black" {}
        _OutlineTex ("OutlineTex", 2D) = "Black" {}
        _OutlineWidth ("Outline Width", Range(0.1, 3)) = 0.5
        _ShadowEdgeStart ("Shadow Edge Start", Range(0,1)) = 0.2
        _ShadowEdgeEnd ("Shadow Edge End", Range(0,1)) = 0.7
        _ShadowValue ("Shadow Value", Range(0,1)) = 0.6
        _Shininess ("Shininess", Range(0.1, 100.0)) = 32.0
        _IDMap ("IDMap", 2D) = "Black" {}
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
            #include "Lighting.cginc"
            #include "Utilities.cginc"

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
            float _ShadowEdgeStart;
            float _ShadowEdgeEnd;
            float _ShadowValue;
            float _Shininess;
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

            half4 frag (v2f i) : SV_Target
            {
                half4 albedo = tex2D(_MainTex, i.uv);
                float3 normal = normalize(i.normal);
                float3 tangent = normalize(i.tangent);
                
                float3 normalWS = SampleNormalMap(_NormalMap, i.uv, normal, tangent);
                //normalWS = UnityObjectToWorldNormal(normal);

                float3 lightDir = _WorldSpaceLightPos0.xyz;
                half3 lightColor = _LightColor0.xyz;
                half diffuse = LightingDiffuse(lightDir, normalWS, 1);
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.positionWS);
                float3 halfVec = normalize(lightDir + viewDir);
                float spec = pow(max(dot(normalWS, halfVec), 0.0), _Shininess);

                float cellShading = smoothstep(_ShadowEdgeStart, _ShadowEdgeEnd, diffuse + spec);
                cellShading = lerp(_ShadowValue, 1, cellShading + albedo.a);

                float3 viewNormal = normalize(mul((float3x3)unity_MatrixV,normalWS));
                float2 matcapUV = 0.5 + 0.5 * viewNormal.xy;
                half4 matcapColor = tex2D(_MatCapTex, matcapUV); 
                float matcapMask = tex2D(_NormalMap, i.uv).b;
                
                half4 finalCol = albedo * cellShading * lightColor.rgbb + matcapColor * matcapMask;
                UNITY_APPLY_FOG(i.fogCoord, finalCol);
                return finalCol;
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
            {   v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                float4 vertex = UnityObjectToClipPos(v.vertex);
                float3 viewNormal = mul((float3x3)UNITY_MATRIX_IT_MV, v.tangent.xyz);
                
                float3 ndcNormal = normalize(TransformViewToProjection(viewNormal.xyz)) * vertex.w;//将法线变换到NDC空间
                float4 nearUpperRight = mul(unity_CameraInvProjection, float4(1, 1, UNITY_NEAR_CLIP_VALUE, _ProjectionParams.y));//将近裁剪面右上角位置的顶点变换到观察空间
                float aspect = abs(nearUpperRight.y / nearUpperRight.x);//求得屏幕宽高比
                ndcNormal.x *= aspect;
                vertex.xy += 0.01 * _OutlineWidth * ndcNormal.xy;
                o.vertex = vertex;
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
