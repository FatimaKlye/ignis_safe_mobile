-- Standardize the application name in About Us copy to "IGNIS SAFE"
-- (previously mixed "Ignis Safe" / "Safe" / "Ignis").
update about_us_name_meanings
set term_en = 'IGNIS',
    term_tl = 'IGNIS'
where section_key = 'ignis_safe' and term_en = 'Ignis';

update about_us_name_meanings
set term_en = 'SAFE',
    term_tl = 'SAFE'
where section_key = 'ignis_safe' and term_en = 'Safe';

update about_us_ignis
set together_en = 'Together, IGNIS SAFE represents protection from fire and fire safety. It reflects a mission focused on preventing fire risks, ensuring preparedness, and keeping people and property safe from fire-related hazards.',
    together_tl = 'Magkasama, ang IGNIS SAFE ay kumakatawan sa proteksyon mula sa sunog at kaligtasan sa sunog. Sumasalamin ito sa isang misyon na nakatuon sa pag-iwas sa panganib ng sunog, pagtitiyak ng kahandaan, at pagpapanatiling ligtas ang mga tao at ari-arian mula sa mga panganib na may kaugnayan sa sunog.',
    focus_heading_en = 'IGNIS SAFE focuses on fire safety, prevention, and emergency preparedness.',
    focus_heading_tl = 'Ang IGNIS SAFE ay nakatuon sa kaligtasan sa sunog, pag-iwas, at paghahanda para sa emerhensiya.',
    essence_en = replace(essence_en, 'Ignis Safe', 'IGNIS SAFE'),
    essence_tl = replace(essence_tl, 'Ignis Safe', 'IGNIS SAFE'),
    team_intro_en = replace(team_intro_en, 'Ignis Safe', 'IGNIS SAFE'),
    team_intro_tl = replace(team_intro_tl, 'Ignis Safe', 'IGNIS SAFE'),
    updated_at = now()
where section_key = 'ignis_safe';
