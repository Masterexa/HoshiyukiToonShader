/** アウトラインシェーダー.
 *
 * @date	2017/12/7
 */
Shader "HoshiyukiToon/Outline"
{
	Properties
	{
		_OutlineColor	("Outline Color", Color) = (.0,.0,.0,1)
		_OutlineSize	("Outline Width", Range(.001,.03)) = .002
	}
	SubShader
	{
		Tags {"RenderType"="Transparent" "LightMode" = "ForwardBase"}
		LOD 100

		Pass
		{
			Name "OUTLINE"
			Tags{"LightMode" = "Always" "Queue"="Transparent"}
			Cull Front
			ZWrite On
			ColorMask RGB
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
				#pragma target 3.0
				#pragma vertex vert
				#pragma fragment frag
				//#pragma multi_compile_fwdbase
				#pragma multi_compile_fog	// make fog work
				#include "HoshiyukiToonCommon.cginc"
				#include "HoshiyukiToonOutline.cginc"

				/* --- Uniforms --- */
					uniform float	_OutlineSize;
					uniform fixed4	_OutlineColor;
				/* end */


				/* --- Typedef --- */
					/** 頂点入力.
					 */
					struct appdata
					{
						float4 vertex	: POSITION;
						float3 normal	: NORMAL;
					};

					/** ピクセルシェーダー入力.
					 */
					struct v2f
					{
						UNITY_FOG_COORDS(1)
						float4	vertex		: SV_POSITION;
						half4	color		: COLOR;
						float4	worldPos	: TEXCOORD0;
					};
				/* end */

				/* --- Shader Functions --- */
					/** 頂点シェーダー.
					 *
					 */
					v2f vert (appdata v)
					{
						float edge = _OutlineSize;
						v2f o;
						o.vertex = UnityObjectToClipPos(v.vertex);

						float3	norm		= normalize( mul( (float3x3)UNITY_MATRIX_IT_MV, float4(v.normal,0) ) );
						float2	offset		= TransformViewToProjection( norm.xy );
						float	fov			= atan( 1 / unity_CameraProjection._m11 ) * 2;

						// Outline translation
						//#ifdef UNITY_Z_0_FAR_FROM_CLIPSPACE
							//o.vertex.xy += offset * fov * UNITY_Z_0_FAR_FROM_CLIPSPACE( o.vertex.z ) * edge;
						//#else
							//o.vertex.xy += offset * edge * fov * (o.vertex.z);
						//#endif


						o.vertex = HTS_expandVertexOutline(_OutlineSize, TransformViewToProjection(norm), o.vertex);


						// GI Calclation
						o.color		= _OutlineColor;
						#ifdef UNITY_LIGHT_PROBE_PROXY_VOLUME
							// Sample Light probe GI
							if (unity_ProbeVolumeParams.x != 1)
							{
								o.color.rgb *= ShadeSHSimpleToon();
							}
							o.worldPos = mul( unity_ObjectToWorld, v.vertex );
						#else
							o.color.rgb *= ShadeSHSimpleToon();
						#endif

						UNITY_TRANSFER_FOG(o,o.vertex);
						return o;
					}
			
					/** フラグメントシェーダー.
					 *
					 */
					fixed4 frag (v2f i) : SV_Target
					{
						// sample the texture
						half4 col = i.color;

						// Sample Proxy Volume GI
						#if defined(UNITY_LIGHT_PROBE_PROXY_VOLUME)
							if (unity_ProbeVolumeParams.x == 1)
							{
								col.rgb *= SHEvalLinearL0L1_SampleProbeVolume_Toon( i.worldPos );
							}
						#endif


						// apply fog
						UNITY_APPLY_FOG(i.fogCoord, col);
						return col;
					}
				/* end */
			ENDCG
		}
	}
}
