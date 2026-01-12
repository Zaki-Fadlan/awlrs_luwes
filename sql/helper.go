package sql

import (
	"bytes"
	"math/rand"

	"github.com/kokizzu/gotro/S"
)

func Where_InIds(ids []string) string {
	len := len(ids) - 1
	if len < 0 {
		return ` IN ('0')` // make sure there are no zero-value id
	}
	buf := bytes.Buffer{}
	buf.WriteString(` IN (`)
	for k, v := range ids {
		buf.WriteString(S.Z(v))
		if k < len { // write except the last one
			buf.WriteRune(',')
		}
	}
	buf.WriteString(`)`)
	return buf.String()
}

func GroupOnly(key string) string {
	if GROUP_ID == `` {
		return ``
	}

	return ` AND ` + key + ` = ` + GROUP_ID
}

func RandomNumString(length int) string {
	const strs = `1234567890`

	b := make([]byte, length)
	for i := range b {
		b[i] = strs[rand.Intn(len(strs))]
	}

	return string(b)
}

func RandomCapitalString(length int) string {
	const strs = `ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890`

	b := make([]byte, length)
	for i := range b {
		b[i] = strs[rand.Intn(len(strs))]
	}

	return string(b)
}
