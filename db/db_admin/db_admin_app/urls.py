from django.urls import path

from . import views

app_name = 'db_admin_app'

urlpatterns = [
    path('', views.IndexView.as_view(), name='index'),
    path('student_count/', views.StudentCountByFormView.as_view(), name='student_count'),
    path('subject_details/', views.SubjectDetailsView.as_view(), name='subject_details'),
    path('generate_student_report/', views.GenerateStudentReportView.as_view(), name='generate_student_report'),
]
