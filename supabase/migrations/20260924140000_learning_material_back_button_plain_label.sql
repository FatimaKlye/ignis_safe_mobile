-- Learning Materials navigation (Module 1): the class detail Back button
-- label is plain text — no leading arrow/chevron symbol.

update public.learning_material_texts
set text_en = btrim(regexp_replace(text_en, '^\s*[«‹←]+\s*', '')),
    text_tl = btrim(regexp_replace(text_tl, '^\s*[«‹←]+\s*', '')),
    updated_at = now()
where module_no = 1
  and text_key = 'class_back_button';
