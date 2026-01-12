package oGroups

import (
	"luwes/sql"
	"testing"

	"github.com/kokizzu/gotro/D/Pg"
	"github.com/kokizzu/gotro/M"
	"github.com/kokizzu/gotro/W"
	"github.com/kokizzu/gotro/X"
	"github.com/stretchr/testify/assert"
)

func TestFindGroup(t *testing.T) {
	group := NewGroupMutator(sql.PG.Adapter)

	t.Run(`insertGroupMustSucceed`, func(t *testing.T) {
		group.Name = "Guest"
		group.Note = "test note"
		group.UniqueId = "UNQ-TEST-88129X"
		group.CreatedBy = 1
		group.UpdatedBy = 1

		assert.NoError(t, group.Insert(), `failed to insert a new group`)

		t.Run(`findGroupByNameMustSucceed`, func(t *testing.T) {
			group.Name = "Guest"
			found := group.FindByName()

			assert.True(t, found)
			t.Log(`Group Name:`, group.Name)
			t.Log(`Group ID:`, group.Id)
		})

		t.Run(`findGroupByIdMustSucceed`, func(t *testing.T) {
			res := One_ByID(int64(group.Id))

			t.Log(`Find By ID: `, X.ToJsonPretty(res))
		})

		t.Run(`searchGroupsByPagination`, func(t *testing.T) {
			posts := &W.Posts{
				SS: M.SS{
					"a":      "search",
					"limit":  "10",
					"offset": "0",
					"order":  `["-name"]`,
				},
			}
			qp := Pg.NewQueryParams(posts, &TM_MASTER)
			Search_ByQueryParams(qp)

			res := M.SX{}
			qp.ToMSX(res)

			t.Log(`Groups by pagination: `, X.ToJsonPretty(res))
		})
	})
}
