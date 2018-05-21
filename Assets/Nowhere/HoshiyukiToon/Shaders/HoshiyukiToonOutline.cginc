#ifndef NWH_HTS_OUTLINE_INC
#define NWH_HTS_OUTLINE_INC

/* includes */
#include "UnityCG.cginc"
#include "HoshiyukiToonCommon.cginc"


inline float4 HTS_expandVertexOutline(float size, half3 projNormal, float4 projPosition) {

	float fov = atan(1 / unity_CameraProjection._m11) * 2;

	projPosition.xy += projNormal.xy * UNITY_Z_0_FAR_FROM_CLIPSPACE(projPosition.z) * size;
	return projPosition;
}

inline half3 HTS_calculateVertexOutlineGI(half3 normal) {

	return ShadeSHSimpleToon();
}

inline half3 HTS_calculatePixelOutlineGI(half3 vertexGI,float4 worldPos) {

	// Sample Proxy Volume GI
	#if defined(UNITY_LIGHT_PROBE_PROXY_VOLUME)
		if( unity_ProbeVolumeParams.x == 1 )
		{
			return SHEvalLinearL0L1_SampleProbeVolume_Toon(worldPos);
		}
	#endif

	return vertexGI;
}


#endif