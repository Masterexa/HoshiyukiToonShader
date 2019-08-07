/** 半透明のシェード.
 *
 * @date	2017/12/7
 */
Shader "HoshiyukiToon/LitFade" {
	Properties {
		// Lit
		_Color					("Color", Color) = (1,1,1,1)
		_MainTex				("Albedo (RGB)", 2D) = "white" {}
		_Cutoff					("Clip Threshold", Range(0,1)) = 0.1
		// Metallic and Smoothness
		_Glossiness				("Smoothness", Range(0,1))=0.5
		[Gamma]_Metallic		("Metallic", Range(0,1))=0.0
		[Gamma]_SpecularFactor	("Specular", Range(0,1))=0.0
		_MetallicGlossMap		("Metallic", 2D)="white"{}
		// Toon
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
		[HideInInspector]						_Blend("Mode", Float) = 0
	}
	SubShader{
		Tags { "RenderType" = "Transparent" "Queue"="Transparent" }
		Cull [_Cull]
		ZWrite Off
		ColorMask RGB
		LOD 200

		Stencil
		{
			Ref 128
			WriteMask 128
			Comp Always
			Pass Replace
			Fail Keep
		}

		CGPROGRAM
			#pragma multi_compile _ NWH_TOON_CUTOUT
			#pragma multi_compile _ NWH_TOON_STANDARDGI
			#pragma surface surfLitBase ToonRampMetallic2 fullforwardshadows addshadow alpha:fade
			#pragma target 3.0
			#define HTS_USE_POINTLIGHTRAMP

			#include "HoshiyukiToonSurfaceLitBase.cginc"
		ENDCG

		UsePass "HoshiyukiToon/Lit/SHADOWCASTER"
	}
	FallBack "Diffuse"
	CustomEditor "HoshiyukiToonShaderEditor.SurfaceShaderInspector"
}
