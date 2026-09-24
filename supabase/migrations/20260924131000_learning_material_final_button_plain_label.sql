-- Learning Materials final completion popup (Modules 1–5): the Start
-- Post-Test/Post-Assessment button label is plain text — no trailing arrow.

-- Modules 3–5: button labels stored in learning_material_texts.
update public.learning_material_texts
set text_en = btrim(regexp_replace(text_en, '\s*[»→›]+\s*$', '')),
    text_tl = btrim(regexp_replace(text_tl, '\s*[»→›]+\s*$', '')),
    updated_at = now()
where (module_no, text_key) in (
  (3, 'm3_lm_015_start_post_assessment'),
  (4, 'dialog_final_button'),
  (5, 'common.start_post_test_arrow')
);

-- Module 1: final dialog stored in learning_materials.content.
update public.learning_materials
set content = jsonb_set(
      jsonb_set(content,
        '{dialogs,final_complete,button_en}',
        to_jsonb(btrim(regexp_replace(content #>> '{dialogs,final_complete,button_en}', '\s*[»→›]+\s*$', '')))),
      '{dialogs,final_complete,button_tl}',
      to_jsonb(btrim(regexp_replace(content #>> '{dialogs,final_complete,button_tl}', '\s*[»→›]+\s*$', ''))))
where module_no = 1
  and content #>> '{dialogs,final_complete,button_en}' is not null
  and content #>> '{dialogs,final_complete,button_tl}' is not null;
