package data
import (
	"database/sql"
	)
	
//Model struct to wrap all data models
type Model struct {
	AuthTokens    *AuthTokenModel
	Districts     *DistrictModel
	Documents     *DocumentModel
	Education     *EducationModel
	Institutions  *InstitutionModel
	Notifications  *NotificationModel
	Qualifications *QualificationModel
	Roles         *RoleModel
	Teachers      *TeacherModel
	Users         *UserModel
}

//NewModel initializes and returns a new Model struct
func NewModel(db *sql.DB) *Model {
	return &Model{
		AuthTokens:    &AuthTokenModel{DB: db},
		Districts:     &DistrictModel{DB: db},
		Documents:     &DocumentModel{DB: db},
		Education:     &EducationModel{DB: db},
		Institutions:  &InstitutionModel{DB: db},
		Notifications:  &NotificationModel{DB: db},
		Qualifications: &QualificationModel{DB: db},
		Roles:         &RoleModel{DB: db},
		Teachers:      &TeacherModel{DB: db},
		Users:         &UserModel{DB: db},
	}
}