Shader "WutheringWave/FaceShader"
{
    Properties
    {
        _MainTex ("Albedo", 2D) = "white" {}
        _FaceSDF ("FaceSDF", 2D) = "white" {}
        _Ramp ("Ramp", 2D) = "white" {}
        _OutlineTex ("OutlineTex", 2D) = "Black" {}
        _OutlineWidth ("Outline Width", Range(0.1, 3)) = 0.5
        _ShadowValue ("Shadow Value", Range(0,1)) = 0.6
        _ShadowFade ("Shadow Fade", Range(0,1)) = 0.2
        _IDMask ("IDMask", 2D) = "white" {}
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
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 color : TEXCOORD1;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _FaceSDF_TexelSize;
            float _ShadowValue;
            float _ShadowFade;

            sampler2D _FaceSDF;
            sampler2D _Ramp;
            sampler2D _IDMask;

            float FaceSDFShadow(sampler2D faceSDF, float2 uv, float3 lightDir, float3 forward, float3 up)
            {
                float3 lightDirIgnorey = normalize(float3(lightDir.x, 0, lightDir.z));
                float3 left = normalize(cross(forward, up));
                
                float flipSign = sign(dot(left, lightDirIgnorey));
                float4 sdf = tex2D(faceSDF, uv * float2(flipSign, 1));
                forward = normalize(forward);
                float lgihtAtten = 1 - dot(lightDirIgnorey, forward);
                float shadow = smoothstep(lgihtAtten,lgihtAtten+_ShadowFade,sdf.r);
                shadow = lerp(_ShadowValue, 1, shadow);
                return shadow;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.color = v.color;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }
            

            fixed4 frag (v2f i) : SV_Target
            {
                half4 albedo = tex2D(_MainTex, i.uv);
                float shadow = FaceSDFShadow(_FaceSDF, i.uv, _WorldSpaceLightPos0, float3(0, 0, 1), float3(0, 1, 0));
                half4 faceMask = half4(i.color, 1);
                half4 id = tex2D(_IDMask, i.uv);
                return albedo * shadow;
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

	    Pass
	    {
		    Name "ShadowCaster"
		    Tags { "LightMode" = "ShadowCaster" }
		    ZWrite On
		    ZTest LEqual

            CGPROGRAM
            // compile directives
            #pragma vertex vert_surf
            #pragma fragment frag_surf

            #include "UnityCG.cginc"

            #pragma target 5.0

            #pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
            #pragma multi_compile_shadowcaster

            // -------- variant for: <when no other keywords are defined>
            #if !defined(INSTANCING_ON)

            #define INTERNAL_DATA
            #define WorldReflectionVector(data,normal) data.worldRefl
            #define WorldNormalVector(data,normal) normal

            // Original surface shader snippet:
            #line 10 ""
            #ifdef DUMMY_PREPROCESSOR_TO_WORK_AROUND_HLSL_COMPILER_LINE_HANDLING
            #endif

            struct v2f_surf {
              V2F_SHADOW_CASTER;

              UNITY_VERTEX_INPUT_INSTANCE_ID
              UNITY_VERTEX_OUTPUT_STEREO
            };

            // vertex shader
            inline v2f_surf vert_surf (appdata_full v) {
              v2f_surf o;
              UNITY_INITIALIZE_OUTPUT(v2f_surf,o);
              TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
              return o;
            }

            // fragment shader
            inline fixed4 frag_surf (v2f_surf IN) : SV_Target {
 	            SHADOW_CASTER_FRAGMENT(IN)
            }
            #endif
            ENDCG
        }
    }
}
