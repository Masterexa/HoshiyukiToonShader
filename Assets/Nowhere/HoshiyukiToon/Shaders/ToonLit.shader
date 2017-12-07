/**	トゥーンシェード.
 *
 * @date	2017/12/7
 */
Shader "HoshiyukiToon/Lit" {
	Properties {
		// Base Color
		_Color						("Color", Color) = (1,1,1,1)
		_MainTex					("Albedo (RGB)", 2D) = "white" {}
		_Cutoff						("Clip Threshold", Range(0,1)) = 0.1
		// Lit
		_ToonTex					("Ramp Texture", 2D) = "white"{}
		_ToonFactor					("Ramp Factor", Range( 0,1 ) ) = 1

		// Lit Options
		[ToggleOff]								_UseStandardGI("Use Standard GI", Float) = 0
		[Enum(UnityEngine.Rendering.CullMode)]	_Cull("Cull Mode", Float ) = 2
		[HideInInspector]						_Blend("Mode", Float) = 0
	}
	SubShader{
		Tags { "RenderType" = "Opaque" }
		Cull [_Cull]
		LOD 200

		CGPROGRAM
			#pragma multi_compile _ NWH_TOON_CUTOUT
			#pragma multi_compile _ NWH_TOON_STANDARDGI
			#pragma surface surf ToonRamp fullforwardshadows addshadow
			#pragma lighting ToonRamp exclude_path:prepass
			#pragma target 3.0
			#include "HoshiyukiToonLighting.cginc"

			fixed		_Cutoff;
			sampler2D	_MainTex;
			fixed4		_Color;

			struct Input {
				float2	uv_MainTex;
			};

			/** サーフェイスシェーダー.
			 *
			 */
			void surf( Input IN, inout SurfaceOutputStandardSpecular o ) {
				fixed4 c		= tex2D( _MainTex, IN.uv_MainTex ) * _Color;
				o.Albedo		= c.rgb;
				o.Alpha			= c.a - _Cutoff;
				CLIP_PROCESS(o)
			}
		ENDCG


		Pass 
        {
			Name "SHADOWCASTER"
            Tags {"LightMode"="ShadowCaster"}
            Cull Off
 
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #include "UnityCG.cginc"
 
            struct v2f {
                V2F_SHADOW_CASTER;
            };
 
            v2f vert(appdata_base v)
            {
                v2f o;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                return o;
            }
 
            float4 frag(v2f i) : SV_Target
            {
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }
	}
	FallBack "Diffuse"
	CustomEditor "NowhereUnityEditor.Rendering.HoshiyukiToonEditor"
}
