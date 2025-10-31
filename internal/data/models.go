package data

import (
	"database/sql"
)

// Model struct to wrap all data models
type Models struct {
	Tokens         *TokenModel
	Districts      *DistrictModel
	Documents      *DocumentModel
	Education      *EducationModel
	Institutions   *InstitutionModel
	Notifications  *NotificationModel
	Qualifications *QualificationModel
	Roles          *RoleModel
	Teachers       *TeacherModel
	Users          *UserModel
}

// NewModels initializes and returns a new Models struct
func NewModels(db *sql.DB) *Models {
	return &Models{
		Tokens:         &TokenModel{DB: db},
		Districts:      &DistrictModel{DB: db},
		Documents:      &DocumentModel{DB: db},
		Education:      &EducationModel{DB: db},
		Institutions:   &InstitutionModel{DB: db},
		Notifications:  &NotificationModel{DB: db},
		Qualifications: &QualificationModel{DB: db},
		Roles:          &RoleModel{DB: db},
		Teachers:       &TeacherModel{DB: db},
		Users:          &UserModel{DB: db},
	}
}
