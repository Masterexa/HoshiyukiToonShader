using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEditor;
using UnityEditor.IMGUI.Controls;
using System;
using System.IO;
using UnityObject = UnityEngine.Object;

namespace HoshiyukiToonShaderEditor.RampUpgradeWizard {

    [System.Flags]
    public enum RampUpgradeOptions {
        CopyFromDirectional = 0x1,
        ApplySingleTexture  = 0x2,
        Asynchronously      = 0x4
    }

    public struct ScheduledMaterial{
        public bool     isScheduled;
        public string   path;
        public Material material;
    }

    public static class RampUpgrader {


        #region Methods
            public static void UpgradeMaterials(ScheduledMaterial[] scheduledMaterials, RampUpgradeOptions options=RampUpgradeOptions.CopyFromDirectional, Texture2D pointRampTexture=null)
            {
                var materials = scheduledMaterials
                    .Where( (it)=>it.isScheduled )
                    .Select( (it)=>it.material )
                    .ToArray()
                ;

                UpgradeMaterials(materials, options, pointRampTexture);
            }


            public static void UpgradeMaterials(Material[] materials, RampUpgradeOptions type=RampUpgradeOptions.CopyFromDirectional, Texture2D pointRampTexture=null) {
                // IDs
                var     directionalTexId    = Shader.PropertyToID("_ToonTex");
                var     pointTexId          = Shader.PropertyToID("_ToonPointLightTex");
                // configs
                bool    isCopyFromDir       = (type & RampUpgradeOptions.CopyFromDirectional)!=0;
                bool    isAsync             = (type & RampUpgradeOptions.Asynchronously)!=0;

                
                for(int i=0; i!=materials.Length; ++i)
                {
                    var it = materials[i];

                    it.SetTexture(
                        pointTexId,
                        isCopyFromDir ? it.GetTexture(directionalTexId) : pointRampTexture
                    );

                    if( isAsync )
                    {
                        EditorUtility.DisplayProgressBar(
                            "Upgrading Mateials",
                            string.Format("({0}/{1}){2}", i+1, materials.Length, it.name),
                            (float)i/(float)materials.Length
                        );
                    }
                }
                if( isAsync )
                {
                    EditorUtility.ClearProgressBar();
                }
                
            }

            public static void FindUnupdatedMaterials(out ScheduledMaterial[] pairs) {

                var myShaders = new []{
                    Shader.Find("HoshiyukiToon/Lit"),
                    Shader.Find("HoshiyukiToon/LitFade"),
                    Shader.Find("HoshiyukiToon/LitOutline"),
                    Shader.Find("HoshiyukiToon/LitFadeOutline")
                };
                var pointTexId = Shader.PropertyToID("_ToonPointLightTex");


                pairs =
                    AssetDatabase.FindAssets("t:Material")
                    .Select( (it)=>AssetDatabase.GUIDToAssetPath(it) )
                    // Build structures for setup
                    .Select( (it)=>new ScheduledMaterial {
                        path        = it,
                        material    = AssetDatabase.LoadAssetAtPath<Material>(it),
                        isScheduled = true
                    })
                    // Find materials that match the conditions
                    .Where((it) =>
                    {
                        if( !myShaders.Any( (shader)=>(it.material.shader==shader) ) )
                        {
                            return false;
                        }
                        return it.material.GetTexture(pointTexId)==null;
                    })
                    .ToArray()
                ;
            }
        #endregion
    }
}