-- An example of implementing a request to obtain data.

--
-- Get the number of students by study form.
--
SELECT
    study_form.form_name AS "Форма обучения",
    COUNT(student.student_id) AS "Количество студентов"
FROM study_form
LEFT JOIN student ON study_form.form_id = student.study_form_id
WHERE study_form.form_name = 'Очная'
GROUP BY study_form.form_name;

--
-- Get hours and report form by discipline.
--
SELECT
    subject.subject_name AS "Дисциплина",
    subject.hours AS "Количество часов",
    report_type.report_type_name AS "Форма отчетности"
FROM subject
LEFT JOIN report_type ON subject.report_type_id = report_type.report_type_id
WHERE subject_name = 'Математика';

--
-- Get student performance.
--
SELECT
    mark.mark_date AS "Дата",
    subject.subject_name AS "Дисциплина",
    mark.mark AS "Оценка"
FROM mark
INNER JOIN student ON mark.student_id = student.student_id
INNER JOIN subject ON mark.subject_id = subject.subject_id
WHERE student.student_id = 1;

