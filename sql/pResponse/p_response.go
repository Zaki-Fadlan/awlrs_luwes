package pResponse

import (
	"github.com/kokizzu/gotro/I"
	"github.com/kokizzu/gotro/M"
	"github.com/kokizzu/gotro/S"
	"github.com/kokizzu/gotro/W"

	"luwes/sql"
)

func NewAjax() W.Ajax {
	return W.Ajax{
		SX: M.SX{
			`is_success`: true,
		},
	}
}
func Prepare(ctx *W.Context, title string, must_login bool) (rm *W.RequestModel) {
	user_id := ctx.Session.GetInt(`user_id`)
	rm = &W.RequestModel{
		Actor:   I.ToS(user_id),
		DbActor: I.ToS(user_id),
		Level:   ctx.Session.GetMSX(`level`),
		Ctx:     ctx,
	}
	is_ajax := ctx.IsAjax()
	if is_ajax {
		rm.Ajax = NewAjaxResponse()
	}
	page := rm.Level.GetMSB(`page`)
	first_segment := ctx.FirstPath()
	is_wm := ctx.IsWebMaster()
	rm.Ok = is_wm || page[first_segment] || first_segment == `guest`
	if rm.Ok {
		// TODO: check access level, or use AuthFilter
	}
	if !rm.Ok {
		// 403
		if is_ajax {
			rm.Ajax.Error(sql.ERR_001_MUST_LOGIN)
			ctx.AppendAjax(rm.Ajax)
			return
		}
		ctx.Title = title
		if must_login {
			Render403(ctx)
		}
	}
	if !is_ajax {
		// GET
		ctx.Title = title
		menus := []string{
			`guest`,
			`owner`,
			`engineer`,
			`superadmin`,
		}
		email := ctx.Session.GetStr(`email`)
		logger := `Not Logged In`
		if email != `` {
			logger = email + ``
		}
		full_name := rm.Level.GetStr(`full_name`)
		if ctx.IsWebMaster() {
			logger += ` <a class="system_admin" href="/system_admin/impersonate/` + rm.Actor + `">` + ` (` + rm.Actor + `)</a>`
		} else {
			logger += full_name
		}
		values := M.SX{
			`title`:        title,
			`email`:        logger,
			`uid`:          user_id,
			`project_name`: ctx.Engine.Name,
			`debug_mode`:   S.IfElse(ctx.Engine.DebugMode, `ALPHA`, ``),
		}
		values[`menus`] = menus
		rm.Level[`values`] = values
		empty := M.SX{}
		for _, menu := range menus {
			values[menu+`_menu`] = ``
			if menu == `guest` || page[menu] || is_wm {
				values[menu+`_menu`] = ctx.PartialNoDebug(`menu/`+menu, empty)
			}
		}
		// L.Describe(ctx.Session.Level)
		// ctx.Render(`menu/index`, values)
	} else {
		// POST
		rm.Posts = ctx.Posts()
		rm.Action = rm.Posts.GetStr(`a`)
		rm.Id = rm.Posts.GetStr(`id`)
	}
	return
}

func Render403(ctx *W.Context) {
	ctx.Title = `403 - Access Denied`
	rm := Prepare(ctx, `403 - Access Denied`, false)
	_ = rm

	locals := rm.Level.GetMSX(`values`)
	locals[`title`] = ctx.Title
	locals[`requested_path`] = ctx.Path
	locals[`webmaster`] = sql.SUPPORT_EMAIL

	ctx.NoLayout = true
	ctx.Render(`403`, locals)
}

func NewAjaxResponse() W.Ajax {
	return W.Ajax{SX: M.SX{`is_success`: true}}
}
