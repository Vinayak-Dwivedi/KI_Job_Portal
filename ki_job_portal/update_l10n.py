import json
import re

def update_file(filepath, class_name, keys, is_abstract=False, locale='en'):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Find all existing getters
    existing_keys = set(re.findall(r'String (?:get )?([a-zA-Z0-9_]+)', content))
    
    missing_keys = [k for k in keys if k not in existing_keys and not k.startswith('@')]
    if not missing_keys:
        return
        
    print(f"Adding {len(missing_keys)} keys to {filepath}")
    
    additions = []
    for key in missing_keys:
        # Check if it has placeholders
        if f"@{key}" in keys and "placeholders" in keys[f"@{key}"]:
            placeholders = keys[f"@{key}"]["placeholders"]
            params = []
            for p, p_info in placeholders.items():
                p_type = p_info.get("type", "String")
                params.append(f"{p_type} {p}")
            param_str = ", ".join(params)
            
            if is_abstract:
                additions.append(f"  String {key}({param_str});")
            else:
                val = keys[key].replace('\n', '\\n').replace("'", "\\'")
                for p in placeholders:
                    val = val.replace("{"+p+"}", f"${p}")
                additions.append(f"  @override\n  String {key}({param_str}) => '{val}';\n")
        else:
            if is_abstract:
                additions.append(f"  String get {key};")
            else:
                val = keys[key].replace('\n', '\\n').replace("'", "\\'")
                additions.append(f"  @override\n  String get {key} => '{val}';\n")
                
    addition_str = "\n".join(additions) + "\n"
    
    if is_abstract:
        content = content.replace("}\n\nclass _AppLocalizationsDelegate", addition_str + "}\n\nclass _AppLocalizationsDelegate")
    else:
        # Insert before the last closing brace
        last_brace = content.rfind('}')
        content = content[:last_brace] + addition_str + content[last_brace:]
        
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

with open('lib/l10n/en.arb', 'r', encoding='utf-8') as f:
    en_keys = json.load(f)

with open('lib/l10n/hi.arb', 'r', encoding='utf-8') as f:
    hi_keys = json.load(f)

update_file('lib/l10n/app_localizations.dart', 'AppLocalizations', en_keys, is_abstract=True)
update_file('lib/l10n/app_localizations_en.dart', 'AppLocalizationsEn', en_keys, is_abstract=False, locale='en')
update_file('lib/l10n/app_localizations_hi.dart', 'AppLocalizationsHi', hi_keys, is_abstract=False, locale='hi')

print("Done")
