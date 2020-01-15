// Upgrade NOTE: upgraded instancing buffer 'Props' to new syntax.

Shader "HoshiyukiToon/Custom/PBSShader" {
	Properties {
        // Your own variables
		_MainTex	("Main Texture", 2D) ="white"{}
		_Color("Color", Color) = (1.0,1.0,1.0,1)
		_Glossiness("Smoothness", Range(0,1))=0.5
		[Gamma]_Metallic("Metallic", Range(0,1))=0.0
		[Gamma]_SpecularFactor("Specular", Range(0,1))=1.0

		// REQUIRED : Lit variables
		_ToonTex	("Directional Ramp", 2D) = "white"{}
        _ToonPointLightTex("Point Ramp", 2D)="white"{}
		_ToonFactor	("Ramp Factor", Range( 0,1 ) ) = 1

		// Outline
		_OutlineColor("Outline Color", Color) = (.0,.0,.0,0.89)
		_OutlineSize("Outline Width", Range(.001,.03)) = .002
		[Enum(UnityEngine.Rendering.CullMode)]_OutlineCull("Outline Cull", Float)=1

        // OPTIONAL:
        [Enum(UnityEngine.Rendering.CullMode)]_Cull("Cull Mode", Float)=2
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		Cull [_Cull]

		CGPROGRAM
			// REQUIRED : Minimum shader options
			#pragma surface surf ToonRampMetallic2 fullforwardshadows addshadow
			#pragma target 3.0
			#include <Assets/Nowhere/HoshiyukiToon/Shaders/HoshiyukiToonLighting.cginc>


            // OPTIONAL : if this keyword is defined, the ramp texture of point light is enabled.
            #pragma multi_compile HTS_USE_POINTLIGHTRAMP


			struct Input {
				float2 uv_MainTex;
			};

            // variables
			sampler2D	_MainTex;
			fixed4		_Color;
			half		_Glossiness;
			half		_Metallic;
			half		_SpecularFactor;
            

            // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		    // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		    // #pragma instancing_options assumeuniformscaling
		    UNITY_INSTANCING_BUFFER_START(Props)
			    // put more per-instance properties here
		    UNITY_INSTANCING_BUFFER_END(Props)


			void surf (Input IN, inout SurfaceOutputStandardSpecular o) {
				fixed4 col = tex2D(_MainTex, IN.uv_MainTex) * _Color;

				o.Specular.r	= _Metallic;
				o.Specular.g	= _SpecularFactor;
				o.Smoothness	= _Glossiness;
				o.Albedo.rgb	= col.rgb;
				o.Alpha			= col.a;
			}
		ENDCG

		// Outline pass
		Pass
		{
			Name "OUTLINE"
			Tags{"LightMode" = "ForwardBase" "Queue"="Transparent"}
			Cull[_OutlineCull]
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

		// OPTIONAL : Shadowcaster for two sided face
		UsePass "HoshiyukiToon/Lit/SHADOWCASTER"
	}
	FallBack "Diffuse"
}
