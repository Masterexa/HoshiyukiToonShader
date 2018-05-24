Shader "HoshiyukiToon/Custom/VertexTest" {
	Properties {

	/* Lit Properties */
        // Your own variables
		_MainTex	("Main Texture", 2D) ="white"{}
		_Color		("Color", Color) = (1.0,1.0,1.0,1)
		_Cutoff		("Cutoff", Range(0,1))=0.5

		// REQUIRED : Lit variables
		_ToonTex	("Ramp Texture", 2D) = "white"{}
		_ToonPointLightTex("Point Ramp", 2D)="white"{}
		_ToonFactor	("Ramp Factor", Range( 0,1 ) ) = 1

		// OPTIONAL : Lit culling Mode
		[Enum(UnityEngine.Rendering.CullMode)]_Cull("Lit Cull", Float)=2


	/* Outline Properties */
        _OutlineColor	("Outline Color", Color) = (.0,.0,.0,1)
		_OutlineSize	("Outline Width", Range(.001,.03)) = .002
		[Enum(UnityEngine.Rendering.CullMode)]_OutlineCull("Outline Cull", Float)=1


	/* Vertex Modification Properties */
        _WaveFrequency("Vertex Wave Frequency", Float)=5
        _WaveScale("Vertex Wave Scale", Float)=0.5
	}
    CGINCLUDE
        #include <UnityCG.cginc>

        // common variables
        sampler2D	_MainTex;
		fixed4		_Color;
        fixed		_Cutoff;
		float		_WaveFrequency;
		float		_WaveScale;


        // common vertex function
        void vertexModification(inout float4 vertex)
		{
            float t = sin((vertex.y+_Time) * _WaveFrequency) + 1.0 * 0.5;
			vertex.xyz += (t * _WaveScale) * float3(1,0,0);
        }

        // common pixel shader function
        void clipMask(float2 texcoord)
		{
            fixed alpha = tex2D(_MainTex, texcoord).a;
            clip(alpha - _Cutoff);
        }
    ENDCG


	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		Cull [_Cull]
		
		CGPROGRAM
			// REQUIRED : Minimum shader options
			#pragma surface surf ToonRamp fullforwardshadows addshadow vertex:vert
			#pragma target 3.0
			#include <Assets/Nowhere/HoshiyukiToon/Shaders/HoshiyukiToonLighting.cginc>

			
			// OPTIONAL : if this keyword is defined, the ramp texture of point light is enabled.
            #define HTS_USE_POINTLIGHTRAMP

			
            /* Input from vertex shader
             */
			struct Input {
				float2 uv_MainTex;
			};
            

            void vert(inout appdata_full v)
            {
				vertexModification(/*inout*/v.vertex);
            }

			void surf (Input IN, inout SurfaceOutputStandardSpecular o)
            {
                clipMask(IN.uv_MainTex);
				fixed4 col = tex2D(_MainTex, IN.uv_MainTex) * _Color;

				o.Albedo.rgb	= col.rgb;
				o.Alpha			= col.a;
			}
		ENDCG


        Pass
		{
			Name "OUTLINE"
			Tags{"LightMode" = "ForwardBase" "Queue"="Transparent+10"}
			Cull [_OutlineCull]
			ZWrite Off
			ColorMask RGB
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
                // REQUIRED : Minimum shader options
				#pragma target 3.0
				#pragma vertex vert
				#pragma fragment frag
				#pragma multi_compile_fog	// make fog work
				#include <Assets/Nowhere/HoshiyukiToon/Shaders/HoshiyukiToonOutline.cginc>


				/* --- Typedef --- */
					struct Input
					{
						UNITY_FOG_COORDS(3)
						float4	vertex		: SV_POSITION;
						fixed4	color		: COLOR;
						float2	texcoord	: TEXCOORD0;
						half3	ambient		: TEXCOORD1;
						float3	worldPos	: TEXCOORD2;
					};
				/* end */


                /* --- uniforms --- */
                    float	_OutlineSize;
                    fixed4	_OutlineColor;
                    half    _OutlineCull;

                    float4  _MainTex_ST;

				/* --- Shader Functions --- */
					Input vert (appdata_base v)
					{
						Input o;
                        half isFrontCull = step(0.1, abs(1-_OutlineCull));


						vertexModification(/*inout*/v.vertex);
                        
						o.vertex	= v.vertex;
						o.texcoord	= TRANSFORM_TEX(v.texcoord.xy, _MainTex);
						o.color		= _OutlineColor;
                        HTS_vertexOutlineOperation(_OutlineSize, isFrontCull, v.normal, /*inout*/o.vertex, /*out*/o.ambient, /*out*/o.worldPos);
						

						UNITY_TRANSFER_FOG(o,o.vertex);
						return o;
					}
			
					fixed4 frag (Input i) : SV_Target
					{
						clipMask(i.texcoord);

						// Apply color and GI
						half4 col;
						HTS_fragmentOutlineOperation(i.color, i.worldPos, i.ambient, /*out*/col);

						// Apply fog
						UNITY_APPLY_FOG(i.fogCoord, col);
						return col;
					}
			ENDCG
		}

		// OPTIONAL : Shadowcaster for two sided face
		UsePass "HoshiyukiToon/Lit/SHADOWCASTER"
	}
	FallBack "Diffuse"
}
