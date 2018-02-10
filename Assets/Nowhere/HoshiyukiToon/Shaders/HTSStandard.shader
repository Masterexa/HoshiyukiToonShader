Shader "HoshiyukiToon/Standard" {
	Properties {
		// Lit
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_Cutoff("Clip Threshold", Range(0,1)) = 0.1
		// Ramp
		_ToonTex("Ramp Texture", 2D) = "white"{}
		_ToonFactor("Ramp Factor", Range( 0,1 ) ) = 1
		// Occlusion
		_OcclusionStrength("Occlusion Strength", Range(0,1))=0
		_OcclusionMap("Occlusion Map", 2D)="white"{}
		// Emission
		_EmissionColor("Color", Color) = (0,0,0)
		_EmissionMap("Emission", 2D) = "white"{}

		// Blending State and CullMode
		[HideInspector]_Mode("__mode", Float)=0.0
		[HideInspector]_SrcBlend("__src", Float)=1.0
		[HideInspector]_DstBlend( "__dst", Float )=0.0
		[HideInspector]_ZWrite( "__zw", Float )=1.0
		[HideInspector]_Cull("Cull Mode", Float)=2.0
	}

	CGINCLUDE
		// Rouhness type
		#define UNITY_SETUP_BRDF_INPUT MettallicSetup
	ENDCG

	SubShader {
		Tags{"RenderType"="Opaque" "PerformanceChecks"="False"}
		LOD 300

		/* Base Forward pass
		 *
		 */
		Pass{
			Name "FORWARD"
			Tags{"LightMode"="ForwardBase"}

			Blend [_SrcBlend][_DstBlend]
			ZWrite [_ZWrite]
			Cull [_Cull]

			CGPROGRAM
				#pragma target 3.0
				#pragma shader_feature _NORMALMAP
				#pragma shader_feature _ ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
				#pragma shader_feature _EMISSION
				#pragma shader_feature _METALLICGLOSSMAP
				
				#pragma shader_feature ___ _DETAIL_MULX2
				#pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
				#pragma shader_feature _ _SPECULARHIGHLIGHTS_OFF
				#pragma shader_feature _ _GLOSSYREFLECTIONS_OFF
				#pragma shader_feature _PARALLAXMAP
				

				#pragma multi_compile_fwdbase
				#pragma multi_compile_fog
				#pragma multi_compile_instancing

				#pragma vertex vertForwardBase
				#pragma fragment fragForwardBase
				#include "HoshiyukiToonCore.cginc"
			ENDCG
		}
	}
}
