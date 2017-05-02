from __future__ import unicode_literals

from django.db import models

# Create your models here.
class Doors(models.Model):
		name = models.CharField(max_length=200, blank=True, default='')
		description = models.CharField(max_length=200, blank=True, default='')
		active_door = models.BooleanField(default=False)
		
		class Meta:
			ordering = ('name',)