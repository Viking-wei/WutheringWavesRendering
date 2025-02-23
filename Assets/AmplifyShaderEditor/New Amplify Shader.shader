// Made with Amplify Shader Editor v1.9.3.3
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "New Amplify Shader"
{
	Properties
	{
		_NormalMap("NormalMap", 2D) = "white" {}
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" }
		Cull Back
		CGPROGRAM
		#pragma target 3.0
		#pragma surface surf Standard keepalpha addshadow fullforwardshadows 
		struct Input
		{
			float2 uv_texcoord;
		};

		uniform sampler2D _NormalMap;
		uniform float4 _NormalMap_ST;
		float4 _NormalMap_TexelSize;


		float3 CombineSamplesSharp128_g1( float S0, float S1, float S2, float Strength )
		{
			{
			    float3 va = float3( 0.13, 0, ( S1 - S0 ) * Strength );
			    float3 vb = float3( 0, 0.13, ( S2 - S0 ) * Strength );
			    return normalize( cross( va, vb ) );
			}
		}


		void surf( Input i , inout SurfaceOutputStandard o )
		{
			float localCalculateUVsSharp110_g1 = ( 0.0 );
			float2 uv_NormalMap = i.uv_texcoord * _NormalMap_ST.xy + _NormalMap_ST.zw;
			float2 temp_output_85_0_g1 = uv_NormalMap;
			float2 UV110_g1 = temp_output_85_0_g1;
			float4 TexelSize110_g1 = _NormalMap_TexelSize;
			float2 UV0110_g1 = float2( 0,0 );
			float2 UV1110_g1 = float2( 0,0 );
			float2 UV2110_g1 = float2( 0,0 );
			{
			{
			    UV110_g1.y -= TexelSize110_g1.y * 0.5;
			    UV0110_g1 = UV110_g1;
			    UV1110_g1 = UV110_g1 + float2( TexelSize110_g1.x, 0 );
			    UV2110_g1 = UV110_g1 + float2( 0, TexelSize110_g1.y );
			}
			}
			float4 break134_g1 = tex2D( _NormalMap, UV0110_g1 );
			float S0128_g1 = break134_g1.r;
			float4 break136_g1 = tex2D( _NormalMap, UV1110_g1 );
			float S1128_g1 = break136_g1.r;
			float4 break138_g1 = tex2D( _NormalMap, UV2110_g1 );
			float S2128_g1 = break138_g1.r;
			float temp_output_91_0_g1 = 1.5;
			float Strength128_g1 = temp_output_91_0_g1;
			float3 localCombineSamplesSharp128_g1 = CombineSamplesSharp128_g1( S0128_g1 , S1128_g1 , S2128_g1 , Strength128_g1 );
			o.Normal = localCombineSamplesSharp128_g1;
			o.Alpha = 1;
		}

		ENDCG
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=19303
Node;AmplifyShaderEditor.TexturePropertyNode;2;-992,0;Inherit;True;Property;_NormalMap;NormalMap;0;0;Create;True;0;0;0;False;0;False;None;96a4ba79ec239fa44a34cf63581a40ee;True;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.FunctionNode;1;-640,-16;Inherit;False;Normal From Texture;-1;;1;9728ee98a55193249b513caf9a0f1676;13,149,0,147,0,143,0,141,0,139,0,151,0,137,0,153,0,159,0,157,0,155,0,135,0,108,0;4;87;SAMPLER2D;0;False;85;FLOAT2;0,0;False;74;SAMPLERSTATE;0;False;91;FLOAT;1.5;False;2;FLOAT3;40;FLOAT3;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;-64,-112;Float;False;True;-1;2;ASEMaterialInspector;0;0;Standard;New Amplify Shader;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;;0;False;;False;0;False;;0;False;;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;12;all;True;True;True;True;0;False;;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;2;15;10;25;False;0.5;True;0;0;False;;0;False;;0;0;False;;0;False;;0;False;;0;False;;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;True;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;;-1;0;False;;0;0;0;False;0.1;False;;0;False;;False;17;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;16;FLOAT4;0,0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;1;87;2;0
WireConnection;0;1;1;40
ASEEND*/
//CHKSM=23BF44546152706D683738A92E9F7751EF0AFC73