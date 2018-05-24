Shader "HoshiyukiToon/Custom/VertexTest" {
	Properties {
        // Your own variables
		_MainTex		("Main Texture", 2D) ="white"{}
		_Color			("Color", Color) = (0.58,0.58,0.58,1)
		// Occlusion
		_OcclusionStrength	("Occlusion Strength", Range(0,1))=0
		_OcclusionMap		("Occlusion Map", 2D)="white"{}

		// REQUIRED : Lit variables
		_ToonTex	("Ramp Texture", 2D) = "white"{}
		_ToonFactor	("Ramp Factor", Range( 0,1 ) ) = 1


		// Vertex modify
		_Freq("Freq", Float)=1
		_Scale("Scale", Float)=0.1
		// Clip mask
		_ClipMaskTex("Clip Mask Tex", 2D)="white"{}
		_ClipMaskThreshold("Threshold", Range(0,1))=0.5


        // OPTIONAL : Outline Variables
        _OutlineColor	("Outline Color", Color) = (.0,.0,.0,1)
		_OutlineSize	("Outline Width", Range(.001,.03)) = .002
	}
	CGINCLUDE
		#include <UnityCG.cginc>

		#define APPDATA_T	appdata_full

		// variables
		uniform float		_Freq;
		uniform float		_Scale;

		uniform sampler2D	_ClipMaskTex;
		uniform	fixed		_ClipMaskThreshold;


		void vertexModify(inout APPDATA_T v) {

			float t = sin((v.vertex.z+_Time) * _Freq) + 1.0 * 0.5;

			v.vertex.xyz += (t * _Scale) * float3(1,0,0);
		}

		void clipMask(float2 texcoord) {

			fixed a = tex2D(_ClipMaskTex, texcoord).a;
			clip(a - _ClipMaskThreshold);
		}

	ENDCG


	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		Cull Off

		CGPROGRAM
			// REQUIRED : Minimum shader options
			#pragma surface surf ToonRamp fullforwardshadows addshadow vertex:vert
			#pragma target 3.0
			#include <Assets/Nowhere/HoshiyukiToon/Shaders/HoshiyukiToonLighting.cginc>


			struct Input {
				float2 uv_MainTex;
			};

			sampler2D	_MainTex;
			fixed4		_Color;
			fixed		_OcclusionStrength;
			sampler2D	_OcclusionMap;


			void vert(inout APPDATA_T v) {
				vertexModify(v);
			}

			/** Your own surface shader
			 */
			void surf (Input IN, inout SurfaceOutputStandardSpecular o) {
				fixed4	col = tex2D(_MainTex, IN.uv_MainTex) * _Color;
				half	oc	= lerp(1, tex2D(_OcclusionMap, IN.uv_MainTex).g, _OcclusionStrength);

				clipMask(IN.uv_MainTex);

				o.Albedo.rgb	= col.rgb;
				o.Occlusion		= oc;
				o.Alpha			= col.a;
			}
		ENDCG


        Pass
		{
			Name "OUTLINE"
			Tags{"LightMode" = "Always" "Queue"="Transparent"}
			Cull Back
			ZWrite Off
			ColorMask RGB
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
				#pragma target 3.0
				#pragma vertex vert
				#pragma fragment frag
				#pragma multi_compile_fog	// make fog work

				//#define HTS_FRONTSIDE_OUTLINE
				#include <Assets/Nowhere/HoshiyukiToon/Shaders/HoshiyukiToonOutline.cginc>

				/* --- Uniforms --- */
					uniform float	_OutlineSize;
					uniform fixed4	_OutlineColor;

					uniform float4	_ClipMaskTex_ST;
				/* end */

				/* --- Typedef --- */
					/** ピクセルシェーダー入力.
					 */
					struct v2f
					{
						UNITY_FOG_COORDS(3)
						float4	vertex		: SV_POSITION;
						fixed4	color		: COLOR;
						float2	texcoord	: TEXCOORD0;
						half3	ambient		: TEXCOORD1;
						float3	worldPos	: TEXCOORD2;
					};
				/* end */



				/* --- Shader Functions --- */
					/** 頂点シェーダー.
					 *
					 */
					v2f vert (APPDATA_T v)
					{
						v2f o;
						vertexModify(v);
						
						o.vertex	= v.vertex;
						o.texcoord	= v.texcoord.xy;
						o.color		= _OutlineColor;
						HTS_vertexOutlineOperation(_OutlineSize, /*is back face culling*/1, v.normal, /*inout*/o.vertex, /*out*/o.ambient, /*out*/o.worldPos);
						

						UNITY_TRANSFER_FOG(o,o.vertex);
						return o;
					}
			
					/** フラグメントシェーダー.
					 *
					 */
					fixed4 frag (v2f i) : SV_Target
					{
						clipMask(i.texcoord);

						// Apply color and GI
						half4 col;
						HTS_fragmentOutlineOperation(i.color, i.worldPos, i.ambient, /*out*/col);

						// Apply fog
						UNITY_APPLY_FOG(i.fogCoord, col);
						return col;
					}
				/* end */
			ENDCG
		}


		// OPTIONAL : Shadowcaster for two sided face
		UsePass "HoshiyukiToon/Lit/SHADOWCASTER"
	}
	FallBack "Diffuse"
}
