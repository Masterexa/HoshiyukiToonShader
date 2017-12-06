/** アウトラインシェーダー.
 *
 * @date	2017/12/7
 */
Shader "HoshiyukiToon/Outline"
{
	Properties
	{
		_OutlineColor	("Outline Color", Color) = (.5,.5,.5,1)
		_OutlineSize	("Outline Width", Range(.001,.03)) = .003
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "LightMode" = "ForwardBase"}
		LOD 100

		Pass
		{
			Name "OUTLINE"
			Tags{"LightMode" = "Always"}
			Cull Front
			ZWrite On
			ColorMask RGB

			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma multi_compile_fog	// make fog work
				#include "HoshiyukiToonCommon.cginc"


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
						float4	vertex	: SV_POSITION;
						half4	color	: COLOR;
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

						float3	norm	= normalize( mul( (float3x3)UNITY_MATRIX_IT_MV, v.normal ) );
						float2	offset	= TransformViewToProjection( norm.xy );
						float	fov		= atan( 1 / unity_CameraProjection._m11 ) * 2;


						#ifdef UNITY_Z_0_FAR_FROM_CLIPSPACE
							o.vertex.xy += offset * UNITY_Z_0_FAR_FROM_CLIPSPACE(o.vertex.z) * edge * fov;
						#else
							o.vertex.xy += offset * o.pos.z * edge;
						#endif

						o.color		= _OutlineColor;
						o.color.rgb *= ShadeSHSimple();
						UNITY_TRANSFER_FOG(o,o.vertex);
						return o;
					}
			
					/** フラグメントシェーダー.
					 *
					 */
					fixed4 frag (v2f i) : SV_Target
					{
						// sample the texture
						fixed4 col = i.color;
						// apply fog
						UNITY_APPLY_FOG(i.fogCoord, col);
						return col;
					}
				/* end */
			ENDCG
		}
	}
}
