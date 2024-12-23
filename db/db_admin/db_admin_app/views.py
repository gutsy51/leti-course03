from django.shortcuts import render
from django.views.generic import TemplateView, FormView
from django.contrib.auth.mixins import LoginRequiredMixin, PermissionRequiredMixin

from .forms import StudyFormSelectForm, SubjectSelectForm, StudentSelectForm
from .models import Student, Mark


def handler403(request, exception):
    template = 'pages/403csrf.html'
    return render(request, template, status=403)


def handler404(request, exception):
    template = 'pages/404.html'
    return render(request, template, status=404)


def handler500(request):
    template = 'pages/500.html'
    return render(request, template, status=500)


class IndexView(TemplateView):
    template_name = 'pages/index.html'


class StudentCountByFormView(LoginRequiredMixin, PermissionRequiredMixin, FormView):
    permission_required = 'db_admin_app.view_student'
    template_name = 'pages/student_count_form.html'
    form_class = StudyFormSelectForm

    def form_valid(self, form):
        study_form = form.cleaned_data['study_form']
        student_count = Student.objects.filter(study_form=study_form).count()
        return render(self.request, self.template_name, {
            'form': form,
            'result': f'Количество студентов для формы обучения "{study_form.form_name}": {student_count}'
        })


class SubjectDetailsView(LoginRequiredMixin, PermissionRequiredMixin, FormView):
    permission_required = 'db_admin_app.view_subject'
    template_name = 'pages/subject_details_form.html'
    form_class = SubjectSelectForm

    def form_valid(self, form):
        subject = form.cleaned_data['subject']
        return render(self.request, self.template_name, {
            'form': form,
            'result': f'Дисциплина: {subject.subject_name}, Часы: {subject.hours}, '
                      f'Форма отчетности: {subject.report_type.report_type_name}'
        })


class GenerateStudentReportView(LoginRequiredMixin, PermissionRequiredMixin, FormView):
    permission_required = 'db_admin_app.view_mark'
    template_name = 'pages/student_report_form.html'
    form_class = StudentSelectForm

    def form_valid(self, form):
        student = form.cleaned_data['student']
        marks = Mark.objects.filter(student=student).select_related('subject')

        # Передача данных в шаблон
        return render(self.request, self.template_name, {
            'form': form,
            'student': student,
            'marks': marks,
        })
