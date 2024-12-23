from django.contrib import admin
from django.contrib.auth.models import Group, Permission
from django.contrib.contenttypes.models import ContentType

from .models import (
    StudentGroup, Mark, ReportType, Specialty,
    Student, StudyForm, Subject
)


# Register groups. Don't create Admin - use superuser instead.
secretary_group, _ = Group.objects.get_or_create(name='Секретарь')
teacher_group, _ = Group.objects.get_or_create(name='Преподаватель')

# Set permissions.
models = [
    StudentGroup, Mark, ReportType, Specialty,
    Student, StudyForm, Subject
]
for model in models:
    content_type = ContentType.objects.get_for_model(model)

    # Set teacher permissions: S/U for marks, S for non-system tables.
    if model == Mark:
        permissions = Permission.objects.filter(
            content_type=content_type,
            codename__in=[
                'view_mark', 'change_mark',
                'view_date', 'change_date',
            ]
        )
        teacher_group.permissions.add(*permissions)
    else:
        permissions = Permission.objects.filter(
            content_type=content_type,
            codename__in=['view_%s' % model._meta.model_name]
        )
        teacher_group.permissions.add(*permissions)

    # Set secretary permissions. S/I/U/D for all non-system tables.
    permissions = Permission.objects.filter(content_type=content_type)
    secretary_group.permissions.add(*permissions)


# Register models.
@admin.register(StudentGroup)
class StudentGroupAdmin(admin.ModelAdmin):
    list_display = ('group_id', 'group_enroll_year')
    list_editable = ('group_enroll_year',)
    list_filter = ('group_enroll_year',)
    search_fields = ('group_id', 'group_enroll_year')
    list_display_links = ('group_id',)


@admin.register(Mark)
class MarkAdmin(admin.ModelAdmin):
    list_display = ('mark_id', 'subject', 'student', 'mark_date', 'mark')
    list_editable = ('mark_date', 'mark')
    list_filter = ('subject', 'student', 'mark_date', 'mark')
    search_fields = ('mark_id', 'subject', 'student', 'mark_date')
    list_display_links = ('mark_id',)

    def get_readonly_fields(self, request, obj=None):
        """Restrict editing of fields other than 'mark' and 'mark_date' for teachers."""
        if request.user.groups.filter(name='Преподаватель').exists():
            return [field.name for field in Mark._meta.get_fields() if field.name not in ['mark', 'mark_date']]
        return super().get_readonly_fields(request, obj)


@admin.register(ReportType)
class ReportTypeAdmin(admin.ModelAdmin):
    list_display = ('report_type_id', 'report_type_name')
    list_display_links = ('report_type_id',)


@admin.register(Specialty)
class SpecialtyAdmin(admin.ModelAdmin):
    list_display = ('specialty_id', 'specialty_code', 'specialty_name')
    list_editable = ('specialty_code', 'specialty_name',)
    search_fields = ('specialty_id', 'specialty_code', 'specialty_name')
    list_display_links = ('specialty_id',)


@admin.register(Student)
class StudentAdmin(admin.ModelAdmin):
    list_display = ('student_id', 'group', 'first_name', 'last_name', 'family_name',)
    list_editable = ('group',)
    list_filter = ('group', 'study_form',)
    search_fields = ('student_id', 'group', 'first_name', 'last_name', 'family_name')
    list_display_links = ('student_id',)


@admin.register(StudyForm)
class StudyFormAdmin(admin.ModelAdmin):
    list_display = ('form_id', 'form_name')
    list_display_links = ('form_id',)


@admin.register(Subject)
class SubjectAdmin(admin.ModelAdmin):
    list_display = ('subject_id', 'specialty', 'subject_name', 'semester', 'hours', 'report_type')
    list_editable = ('specialty', 'semester', 'hours', 'report_type')
    list_filter = ('specialty', 'semester', 'report_type')
    search_fields = ('subject_id', 'specialty', 'subject_name', 'semester', 'hours', 'report_type')
    list_display_links = ('subject_id',)


admin.site.empty_value_display = 'Не задано'

