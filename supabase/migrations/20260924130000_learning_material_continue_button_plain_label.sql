-- Learning Materials progress/completion popups (Modules 1–5): the Continue
-- button label is plain text — no trailing arrow/chevron symbol.

-- Modules 2–5: button labels stored in learning_material_texts.
update public.learning_material_texts
set text_en = 'Continue',
    text_tl = 'Magpatuloy',
    updated_at = now()
where (module_no, text_key) in (
  (2, 'dialog_continue_button'),
  (3, 'm3_lm_012_continue'),
  (4, 'dialog_continue_button'),
  (5, 'common.continue_arrow')
);

-- Module 1: section-complete dialogs stored in learning_materials.content.
update public.learning_materials
set content = jsonb_set(
      jsonb_set(
        jsonb_set(
          jsonb_set(content,
            '{dialogs,page_1_complete,button_en}', '"Continue"'),
          '{dialogs,page_1_complete,button_tl}', '"Magpatuloy"'),
        '{dialogs,page_2_complete,button_en}', '"Continue"'),
      '{dialogs,page_2_complete,button_tl}', '"Magpatuloy"')
where module_no = 1
  and content #> '{dialogs,page_1_complete}' is not null
  and content #> '{dialogs,page_2_complete}' is not null;
