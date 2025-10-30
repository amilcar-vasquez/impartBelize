package data

import (
	"strings"

	"github.com/amilcar-vasquez/impartBelize/internal/validator"
)

// The Filters type will contain the fields related to pagination
// and eventually the fields related to sorting.
type Filters struct {
	Page         int      // which page number does the client want
	PageSize     int      // how many records per page
	Sort         string   // which column do we want to sort by
	SortSafelist []string // list of columns that are allowed to be sorted by
}

// type to hold page metadata
type Metadata struct {
	CurrentPage  int `json:"current_page,omitempty"`
	PageSize     int `json:"page_size,omitempty"`
	FirstPage    int `json:"first_page,omitempty"`
	LastPage     int `json:"last_page,omitempty"`
	TotalRecords int `json:"total_records,omitempty"`
}

// Next we validate page and PageSize
// We follow the same approach that we used to validate a Comment
func ValidateFilters(v *validator.Validator, f Filters) {
	v.Check(f.Page > 0, "page", "must be greater than zero")
	v.Check(f.Page <= 500, "page", "must be a maximum of 500")
	v.Check(f.PageSize > 0, "page_size", "must be greater than zero")
	v.Check(f.PageSize <= 100, "page_size", "must be a maximum of 100")
	// Check if sort fields provided are valid
	// We will implement PermittedValue() later
	v.Check(validator.PermittedValue(f.Sort, f.SortSafelist...), "sort", "invalid sort value")

}

// calculate how many records to send back
func (f Filters) limit() int {
	return f.PageSize
}

// calculate the offset so that we remember how many records have
// been sent and how many remain to be sent
func (f Filters) offset() int {
	return (f.Page - 1) * f.PageSize
}

// calculate the metadata
func calculateMetadata(totalRecords, page, pageSize int) Metadata {
	if totalRecords == 0 {
		return Metadata{}
	}
	return Metadata{
		CurrentPage:  page,
		PageSize:     pageSize,
		FirstPage:    1,
		LastPage:     (totalRecords + pageSize - 1) / pageSize,
		TotalRecords: totalRecords,
	}
}

// Implement the sorting feature
func (f Filters) sortColumn() string {
	for _, safeValue := range f.SortSafelist {
		if f.Sort == safeValue {
			column := strings.TrimPrefix(f.Sort, "-")
			// Map API field names to database column names
			switch column {
			// User table mappings
			case "id":
				return "user_id"
			// Course table mappings
			case "course_id":
				return "c.course_id"
			case "course_name":
				return "c.course_name"
			case "category_name":
				return "cc.category_name"
			case "credit_hours":
				return "c.credit_hours"
			// Facilitator table mappings
			case "facilitator_id":
				return "f.facilitator_id"
			case "last_name":
				return "f.last_name"
			case "first_name":
				return "f.first_name"
			case "rating":
				return "f.rating"
			// Course Category table mappings
			case "category_id":
				return "category_id"
			// Rank table mappings
			case "rank_id":
				return "rank_id"
			case "rank_name":
				return "rank_name"
			case "abbreviation":
				return "abbreviation"
			// Region table mappings
			case "region_id":
				return "region_id"
			case "region_name":
				return "region_name"
			// Formation table mappings (with joins)
			case "formation_id":
				return "f.formation_id"
			case "formation_name":
				return "f.formation_name"
			// Role table mappings
			case "role_id":
				return "role_id"
			case "role_name":
				return "role_name"
			default:
				return column
			}
		}
	}
	// don't allow the operation to continue
	// if case of SQL injection attack
	panic("unsafe sort parameter: " + f.Sort)
}

// Get the sort order
func (f Filters) sortDirection() string {
	if strings.HasPrefix(f.Sort, "-") {
		return "DESC"
	}
	return "ASC"
}
