# This is an auto-generated Django model module.
# You'll have to do the following manually to clean this up:
#   * Rearrange models' order
#   * Make sure each model has one field with primary_key=True
#   * Make sure each ForeignKey and OneToOneField has `on_delete` set to the desired behavior
#   * Remove `managed = False` lines if you wish to allow Django to create, modify, and delete the table
# Feel free to rename the models, but don't rename db_table values or field names.
from django.db import models


class StudentGroup(models.Model):
    group_id = models.SmallIntegerField(
        primary_key=True, verbose_name='ID группы'
    )
    group_enroll_year = models.SmallIntegerField(
        verbose_name='Год поступления'
    )

    def __str__(self):
        return f'{self.group_id}'

    class Meta:
        managed = False
        verbose_name = 'группа'
        verbose_name_plural = 'Группы'
        ordering = ['group_id']
        db_table = 'student_group'


class Mark(models.Model):
    mark_id = models.AutoField(
        primary_key=True, verbose_name='ID оценки'
    )
    subject = models.ForeignKey(
        'Subject',
        on_delete=models.CASCADE,
        null=False,
        verbose_name='Дисциплина'
    )
    student = models.ForeignKey(
        'Student',
        on_delete=models.CASCADE,
        null=False,
        verbose_name='Студент'
    )
    mark_date = models.DateField(
        verbose_name='Дата выставления'
    )
    mark = models.SmallIntegerField(
        blank=True, null=True, verbose_name='Оценка'
    )

    def __str__(self):
        return f'Оценка студента {self.student} по дисциплине {self.subject}: {self.mark or "N"}'

    class Meta:
        managed = False
        verbose_name = 'оценка'
        verbose_name_plural = 'Оценки'
        ordering = ['-mark_id']
        db_table = 'mark'


class ReportType(models.Model):
    report_type_id = models.SmallIntegerField(
        primary_key=True, verbose_name='ID формы отчетности'
    )
    report_type_name = models.CharField(
        max_length=64, verbose_name='Форма отчетности'
    )

    def __str__(self):
        return f'{self.report_type_name}'

    class Meta:
        managed = False
        verbose_name = 'форма отчетности'
        verbose_name_plural = 'Формы отчетности'
        ordering = ['report_type_id']
        db_table = 'report_type'


class Specialty(models.Model):
    specialty_id = models.SmallAutoField(
        primary_key=True, verbose_name='ID специальности'
    )
    specialty_code = models.CharField(
        max_length=16, verbose_name='Код специальности'
    )
    specialty_name = models.CharField(
        max_length=256, verbose_name='Название специальности'
    )

    def __str__(self):
        return f'{self.specialty_code} - {self.specialty_name}'

    class Meta:
        managed = False
        verbose_name = 'специальность'
        verbose_name_plural = 'Специальности'
        ordering = ['specialty_code']
        db_table = 'specialty'


class Student(models.Model):
    student_id = models.AutoField(
        primary_key=True, verbose_name='ID студента'
    )
    first_name = models.CharField(
        max_length=64, verbose_name='Имя'
    )
    last_name = models.CharField(
        max_length=64, verbose_name='Фамилия'
    )
    family_name = models.CharField(
        max_length=64, blank=True, null=True, verbose_name='Отчество'
    )
    study_form = models.ForeignKey(
        'StudyForm',
        on_delete=models.DO_NOTHING,
        verbose_name='Форма обучения'
    )
    group = models.ForeignKey(
        'StudentGroup',
        on_delete=models.DO_NOTHING,
        verbose_name='Группа',
    )

    def __str__(self):
        return (f'{self.last_name} {self.first_name[0]}. '
                f'{self.family_name[0]}.')

    class Meta:
        managed = False
        verbose_name = 'студент'
        verbose_name_plural = 'Студенты'
        ordering = ['group', 'last_name', 'first_name', 'family_name']
        db_table = 'student'


class StudyForm(models.Model):
    form_id = models.SmallIntegerField(
        primary_key=True, verbose_name='ID формы обучения'
    )
    form_name = models.CharField(
        max_length=64, verbose_name='Форма обучения'
    )

    def __str__(self):
        return f'{self.form_name}'

    class Meta:
        managed = False
        verbose_name = 'форма обучения'
        verbose_name_plural = 'Формы обучения'
        ordering = ['form_id']
        db_table = 'study_form'


class Subject(models.Model):
    subject_id = models.AutoField(
        primary_key=True, verbose_name='ID дисциплины'
    )
    specialty = models.ForeignKey(
        Specialty,
        on_delete=models.SET_NULL,
        blank=True, null=True,
        verbose_name='Специальность'
    )
    subject_name = models.CharField(
        max_length=256, verbose_name='Название'
    )
    semester = models.SmallIntegerField(
        verbose_name='Семестр'
    )
    hours = models.SmallIntegerField(
        blank=True, null=True, verbose_name='Часы'
    )
    report_type = models.ForeignKey(
        ReportType,
        on_delete=models.SET_NULL,
        blank=True, null=True,
        verbose_name='Форма отчетности'
    )

    def __str__(self):
        return f'{self.subject_name}'

    class Meta:
        managed = False
        verbose_name = 'дисциплина'
        verbose_name_plural = 'Дисциплины'
        ordering = ['subject_id']
        db_table = 'subject'
