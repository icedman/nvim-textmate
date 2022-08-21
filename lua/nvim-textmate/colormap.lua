local scope_hl_map = {
	{ "type", "StorageClass" },
	{ "storage.type", "Identifier" },
	{ "constant", "Constant" },
	{ "constant.numeric", "Number" },
	{ "constant.character", "Character" },
	{ "primitive", "Boolean" },
	{ "keyword", "Define" },
	{ "declaration", "Conditional" },
	{ "control", "Conditional" },
	{ "operator", "Operator" },
	{ "directive", "PreProc" },
	{ "require", "Include" },
	{ "import", "Include" },
	{ "function", "Function" },
	{ "struct", "Structure" },
	{ "class", "Structure" },
	{ "modifier", "StorageClass" },
	{ "namespace", "StorageClass" },
	{ "scope", "StorageClass" },
	{ "name.type", "Variable" },
	{ "tag", "Tag" },
	{ "name.tag", "StorageClass" },
	{ "attribute", "Variable" },
	{ "property", "Variable" },
	{ "heading", "markdownH1" },
	{ "string", "String" },
	{ "string.other", "Label" },
	{ "comment", "Comment" },
}

return {
	scope_hl_map = scope_hl_map,
}
