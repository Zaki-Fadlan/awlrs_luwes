package oUsers

import (
	"fmt"
	"luwes/sql"
	"luwes/sql/oGroups"
	"testing"
	"time"

	"github.com/kokizzu/gotro/X"
	"github.com/stretchr/testify/assert"
)

func TestUsers(t *testing.T) {
	t.Run(`insertGroup`, func(t *testing.T) {
		group := oGroups.NewGroupMutator(sql.PG.Adapter)
		group.Name = "Black Org"
		group.Note = "test note"
		group.UniqueId = "UNQ-TEST-88129X"
		group.CreatedBy = 1
		group.UpdatedBy = 1

		assert.NoError(t, group.Insert(), `failed to insert a new group`)

		t.Run(`insertUser`, func(t *testing.T) {
			rawPassword := "vodka43023#szX"

			usr := NewUser()
			usr.CreatedAt = time.Now()
			usr.UpdatedAt = time.Now()
			usr.Email = `vodka390@gmail.com`
			usr.Verified = true
			usr.Note = `test user`
			usr.GroupId = int64(group.Id)
			usr.Phone = `08734739209`
			usr.FullName = `Vodka`
			usr.UpdatedBy = 1
			usr.CreatedBy = 1
			usr.IsDeleted = false
			usr.Data = "{}"
			usr.Password = rawPassword

			assert.NoError(t, usr.DoInsert(), `failed to insert a new user`)

			t.Run(`findIdByPhone`, func(t *testing.T) {
				userId := FindID_ByPhone(usr.Phone)
				fmt.Println(`Find ID By Phone: `, userId)
			})

			t.Run(`findIdByIdentByPass`, func(t *testing.T) {
				userId := FindID_ByIdent_ByPass(usr.Email, usr.Password)
				fmt.Println(`Find ID By Ident and Pass: `, userId)
			})

			t.Run(`findIdByEmail`, func(t *testing.T) {
				res := FindID_ByEmail(usr.Email)
				fmt.Println(`Find ID By Email: `, res)
			})

			t.Run(`findOneById`, func(t *testing.T) {
				result := One_ByID(usr.Id)

				fmt.Println(`Find One By ID: `, X.ToJsonPretty(result))
			})

			t.Run(`findNameEmailsById`, func(t *testing.T) {
				name, email := Name_Emails_ByID(usr.Id)

				fmt.Println(`Name: `, name)
				fmt.Println(`Email: `, email)
			})

			t.Run(`findIdNameEmailUpdatedByPhone`, func(t *testing.T) {
				result := Id_Name_Email_UpdatedAt_ByPhone(usr.Phone)

				fmt.Println(`Find ID, Name, Email, Updated, By Phone: `, X.ToJsonPretty(result))
			})

			t.Run(`findIdNameEmailUpdatedAtByIdentByPass`, func(t *testing.T) {
				result := Id_Name_Email_UpdatedAt_ByIdentByPass(usr.Email, rawPassword)

				fmt.Println(`Find ID, Name, Email, Updated, By Email and Password: `, X.ToJsonPretty(result))
			})

			t.Run(`findIdByCompactNameByEmail`, func(t *testing.T) {
				userId := FindID_ByCompactName_ByEmail(usr.Phone, usr.Email)

				fmt.Println(`Find ID By Compact Name and Email: `, userId)
			})
		})
	})
}
