from django import forms
from .models import StudyForm, Subject, Student


class StudyFormSelectForm(forms.Form):
    study_form = forms.ModelChoiceField(
        queryset=StudyForm.objects.all(),
        label='Выберите форму обучения',
        widget=forms.Select(attrs={'class': 'form-control'})
    )


class SubjectSelectForm(forms.Form):
    subject = forms.ModelChoiceField(
        queryset=Subject.objects.all(),
        label='Выберите дисциплину',
        widget=forms.Select(attrs={'class': 'form-control'})
    )


class StudentSelectForm(forms.Form):
    student = forms.ModelChoiceField(
        queryset=Student.objects.all(),
        label='Выберите студента',
        widget=forms.Select(attrs={'class': 'form-control'})
    )
