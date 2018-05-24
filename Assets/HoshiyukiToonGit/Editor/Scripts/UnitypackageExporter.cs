using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEditor;

namespace HoshiyukiToonShaderEditor{

	///<summary>NewBehaviourScript</summary>
	///<remarks>
	///Use this for control objects in a scene.
	///</remarks>
	public static class UnitypackageExporter{

        #region Class
            #region Fields
                static readonly string[]    sk_exportAssetPathes = {
                    "Assets/Editor Default Resources/HoshiyukiToonEditor",
                    "Assets/ScriptTemplates",
                    "Assets/Nowhere/HoshiyukiToon"
                };
			#endregion

			#region Methods

                [MenuItem("HoshiyukiToon/Export Package")]
                static void ExportPackage() {
                    // 
                    var path = EditorUtility.SaveFilePanel("Export HoshiyukiToon Package", Application.dataPath, "HoshiyukiToonShader", "unitypackage");
                    if( string.IsNullOrEmpty(path) )
                    {
                        return;
                    }
                    
                    AssetDatabase.ExportPackage(sk_exportAssetPathes, path, ExportPackageOptions.Recurse|ExportPackageOptions.Interactive);
                }
			#endregion
		#endregion
	}
}