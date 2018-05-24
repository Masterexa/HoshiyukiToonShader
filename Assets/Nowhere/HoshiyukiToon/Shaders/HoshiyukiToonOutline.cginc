#ifndef NWH_HTS_OUTLINE_INC
#define NWH_HTS_OUTLINE_INC

/* includes */
#include "UnityCG.cginc"
#include "HoshiyukiToonCommon.cginc"


inline float4 HTS_expandVertexOutline(float size, half3 projNormal, float4 projPosition, float isBackCull) {

	float fov = atan(1 / unity_CameraProjection._m11) * 2;

	projPosition.xy += projNormal.xy * UNITY_Z_0_FAR_FROM_CLIPSPACE(projPosition.z) * size;
	projPosition.z -= 0.01 * isBackCull;
	return projPosition;
}

inline half3 HTS_calculateVertexOutlineGI() {

	return SHEvalLinearL0L1_Toon();
}

inline half3 HTS_calculatePixelOutlineGI(half3 ambient,float3 worldPos) {

	// Sample Proxy Volume GI
	#if defined(UNITY_LIGHT_PROBE_PROXY_VOLUME)
		if( unity_ProbeVolumeParams.x == 1 )
		{
			return SHEvalLinearL0L1_SampleProbeVolume_Toon(worldPos);
		}
	#endif

	return ambient;
}

inline void HTS_vertexOutlineOperation(float size, float isBackCull, float3 N, inout float4 vertex, out half3 ambient, out float3 worldPos)
{
	N = normalize(mul((float3x3)UNITY_MATRIX_IT_MV, float4(N, 0)));

	// transformations
	worldPos	= mul(unity_ObjectToWorld, vertex).xyz;
	vertex		= UnityObjectToClipPos(vertex);

	// Expand vertex
	vertex = HTS_expandVertexOutline(size, TransformViewToProjection(N), vertex, isBackCull);
	// calculate GI
	ambient = HTS_calculateVertexOutlineGI();
}

inline void HTS_fragmentOutlineOperation(fixed4 albedo, float3 worldPos, half3 ambient, out half4 outColor)
{
	outColor		= albedo;
	outColor.rgb	*= HTS_calculatePixelOutlineGI(ambient, worldPos);
}

#endif