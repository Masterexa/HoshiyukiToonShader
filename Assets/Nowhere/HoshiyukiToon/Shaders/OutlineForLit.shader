Shader "Hidden/HoshiyukiToon/OutlineForLit"
{
	Properties
	{
	}
	SubShader
	{
		Tags{"RenderType" = "Opaque"}
		LOD 100

		// Outline pass
		Pass
		{
			Name "OUTLINE"
			Tags{"LightMode" = "ForwardBase" "Queue"="Transparent"}
			Cull [_OutlineCull]
			ZWrite On
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

		// Outline pass
		Pass
		{
			Name "OUTLINE_TRANSPARENT"
			Tags{"LightMode" = "ForwardBase" "Queue"="Transparent+10"}
			Cull [_OutlineCull]
			ZWrite Off
			ColorMask RGB
			Blend SrcAlpha OneMinusSrcAlpha

			// Cutout outline from lit surface
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
				#pragma vertex vertOutlineBase
				#pragma fragment fragOutlineBase
				#pragma multi_compile_fog	// make fog work
				#pragma multi_compile _ NWH_TOON_CUTOUT

				#include "HoshiyukiToonSurfaceOutlineBase.cginc"
			ENDCG
		}
	}
}
