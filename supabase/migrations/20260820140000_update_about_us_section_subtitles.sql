-- Refresh About Us card subtitles for the redesigned two-group layout
-- (ABOUT IGNIS SAFE / SAFETY & CONTACT INFORMATION). bfp_dasmarinas already
-- matched the requested copy, so it is left unchanged.
update about_us_sections
set subtitle_en = 'Mission, identity, developers, and adviser',
    subtitle_tl = 'Misyon, pagkakakilanlan, mga developer, at tagapayo'
where section_key = 'ignis_safe';

update about_us_sections
set subtitle_en = 'BFP and emergency hotlines',
    subtitle_tl = 'Mga hotline ng BFP at emergency'
where section_key = 'emergency_contacts';

update about_us_sections
set subtitle_en = 'Fire stations by Cavite district',
    subtitle_tl = 'Mga istasyon ng bumbero ayon sa distrito ng Cavite'
where section_key = 'cavite_directory';
