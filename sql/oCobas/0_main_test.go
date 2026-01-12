package oCobas

import (
	"fmt"
	"testing"

	"github.com/kokizzu/gotro/S"
)

func TestHashPassword(t *testing.T) {
	fmt.Println(S.HashPassword(`test123`))
}
