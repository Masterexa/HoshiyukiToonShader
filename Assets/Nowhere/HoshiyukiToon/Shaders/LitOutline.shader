/** アウトライン付きのトゥーンシェード.
 *
 * @date	2017/12/7
 */
Shader "HoshiyukiToon/LitOutline"
{
	Properties
	{
		// Lit
		_Color		("Color", Color) = (0.5859,0.5859,0.5859,1)
		_MainTex	("Albedo (RGB)", 2D) = "white" {}
		_Cutoff		("Clip Threshold", Range(0,1))=0.1
		_ToonTex	("Ramp Texture", 2D) = "white"{}
		_ToonPointLightTex("Point Light Ramp Texture", 2D) = "white"{}
		_ToonFactor	("Ramp Factor", Range( 0,1 ) ) = 1
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
		Tags{"RenderType" = "Opaque"}
		UsePass "HoshiyukiToon/Lit/FORWARD"
		UsePass "HoshiyukiToon/Lit/SHADOWCASTER"

		// Outline pass
		Pass
		{
			Name "OUTLINE"
			Tags{"LightMode" = "Always" "Queue"="Transparent"}
			Cull [_OutlineCull]
			ZWrite Off
			ColorMask RGB
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
				#pragma target 3.0
				#pragma vertex vertOutlineBase
				#pragma fragment fragOutlineBase
				#pragma multi_compile_fog	// make fog work
				#pragma multi_compile _ NWH_TOON_CUTOUT

				#include "HoshiyukiToonSurfaceOutlineBase.cginc"
			ENDCG
		}
	}
	Fallback "Diffuse"
	CustomEditor "NowhereUnityEditor.Rendering.HoshiyukiToonEditor"
}
