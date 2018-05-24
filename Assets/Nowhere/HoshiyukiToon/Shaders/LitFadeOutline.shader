/** アウトライン付きのトゥーンシェード.
 *
 * @date	2017/12/7
 */
Shader "HoshiyukiToon/LitFadeOutline"
{
	Properties
	{
		// Lit
		_Color				("Color", Color) = (0.5859,0.5859,0.5859,1)
		_MainTex			("Albedo (RGB)", 2D) = "white" {}
		_Cutoff				("Clip Threshold", Range(0,1)) = 0.1
		_ToonTex			("Ramp Texture", 2D) = "white"{}
		_ToonPointLightTex	("Point Light Ramp Texture", 2D) = "white"{}
		_ToonFactor			("Ramp Factor", Range( 0,1 ) ) = 1
		// Occlusion
		_OcclusionStrength	( "Occlusion Strength", Range( 0,1 ) )=0
		_OcclusionMap		( "Occlusion Map", 2D )="white"{}
		// Emission
		_EmissionColor	( "Color", Color ) = (0,0,0)
		_EmissionMap	( "Emission", 2D ) = "white"{}
		// Lit Options
		[ToggleOff]								_UseStandardGI("Use Standard GI", Float) = 0
		[Enum(UnityEngine.Rendering.CullMode)]	_Cull("Cull Mode", Float ) = 2
		[HideInInspector]						_Blend( "Mode", Float ) = 0
			
		// Outline
		_OutlineColor( "Outline Color", Color ) = (.0,.0,.0,0.89)
		_OutlineSize( "Outline Width", Range( .001,.03 ) ) = .002
		[Enum(UnityEngine.Rendering.CullMode)]_OutlineCull("Outline Cull", Float)=1
	}
	SubShader
	{
		Tags{"RenderType" = "Transparent" "Queue"="Transparent"}
		UsePass "HoshiyukiToon/LitFade/FORWARD"
		UsePass "HoshiyukiToon/Lit/SHADOWCASTER"

		// Outline pass
		Pass
		{
			Name "OUTLINE"
			Tags{"LightMode" = "Always" "Queue"="Transparent+10"}
			Cull [_OutlineCull]
			ZWrite Off
			ColorMask RGB
			Blend SrcAlpha OneMinusSrcAlpha

			Stencil
			{
				Ref 128
				ReadMask 128
				Comp NotEqual
				Pass Keep
				Fail Keep
			}

			CGPROGRAM
				#pragma target 3.0
				#pragma vertex vert
				#pragma fragment frag
				#pragma multi_compile_fog	// make fog work
				#pragma multi_compile _ NWH_TOON_CUTOUT

				//#define HTS_FRONTSIDE_OUTLINE
				#include <Assets/Nowhere/HoshiyukiToon/Shaders/HoshiyukiToonOutline.cginc>

				/* --- Uniforms --- */
					uniform float	_OutlineSize;
					uniform fixed4	_OutlineColor;
					uniform	fixed	_OutlineCull;

					fixed		_Cutoff;
					sampler2D	_MainTex;
					fixed4		_Color;
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

					void clipMask(float2 texcoord) {

						#ifdef NWH_TOON_CUTOUT
							fixed a = tex2D(_MainTex, texcoord).a * _Color.a;
							clip(a - _Cutoff);
						#endif
					}

				/* --- Shader Functions --- */
					/** 頂点シェーダー.
					 *
					 */
					v2f vert (appdata_full v)
					{
						v2f o;
						
						fixed isBackCull = step(0.1, abs(1-_OutlineCull));

						o.vertex	= v.vertex;
						o.texcoord	= v.texcoord.xy;
						o.color		= _OutlineColor;
						HTS_vertexOutlineOperation(_OutlineSize, isBackCull, v.normal, /*inout*/o.vertex, /*out*/o.ambient, /*out*/o.worldPos);
						

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
	}
	Fallback "Diffuse"
	CustomEditor "NowhereUnityEditor.Rendering.HoshiyukiToonEditor"
}
