@echo off
setlocal EnableDelayedExpansion
set MSVCLINE=
if not exist msvc.csv (
  for %%f in (*.cpp) do (
    set FILE=%%~nf
    if "!MSVCLINE!" == "" (
      set MSVCLINE="!FILE!"
    ) else (
      set MSVCLINE=!MSVCLINE!,"!FILE!"
    )
  )
  echo !MSVCLINE! >> msvc.csv
  echo !MSVCLINE! >> msvc_clang.csv
)
set MSVCLINE=
echo ^<?xml version="1.0" encoding="UTF-8"?^> > results.xml
echo ^<testsuite name="constexprs"^> >> results.xml
for %%f in (*.cpp) do (
  set FILE=%%~nf
  cl /EHsc /c /O2 /GS- /GR /Gy /Zc:inline /DBOOST_OUTCOME_ENABLE_ADVANCED=1 /D_UNICODE=1 /DUNICODE=1 /DNDEBUG %%f
  dumpbin /disasm !FILE!.obj > !FILE!.msvc.S
  del !FILE!.obj
  set LINE=
  for /f %%i in ('count_opcodes.py !FILE!.msvc.S') do set LINE=%%i
  if "!MSVCLINE!" == "" (
    set MSVCLINE=!LINE!
  ) else (
    set MSVCLINE=!MSVCLINE!,!LINE!
  )
  echo Opcodes generated by MSVC: !LINE!

  rem "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\Clang 3.7\bin\amd64\clang" -std=c++14 -c -O3 -fexceptions -DBOOST_OUTCOME_ENABLE_ADVANCED=1 -D_UNICODE=1 -DUNICODE=1 -DNDEBUG %%f
  clang -std=c++14 -c -O3 -fexceptions -DBOOST_OUTCOME_ENABLE_ADVANCED=1 -D_UNICODE=1 -DUNICODE=1 -DNDEBUG %%f
  dumpbin /disasm !FILE!.o > !FILE!.msvc_clang.S
  del !FILE!.o
  set LINE=
  for /f %%i in ('count_opcodes.py !FILE!.msvc_clang.S') do set LINE=%%i
  if "!CLANGLINE!" == "" (
    set CLANGLINE=!LINE!
  ) else (
    set CLANGLINE=!CLANGLINE!,!LINE!
  )
  echo Opcodes generated by clang: !LINE!

  if not "!FILE:min_=!" == "!FILE!" (
      echo   ^<testcase name="!FILE!.msvc"^> >> results.xml
      if !LINE! GTR 7 (
        if "!FILE!" == "min_monad_construct_exception_move_destruct" (
          echo     ^<skipped/^> >> results.xml
        ) else if "!FILE!" == "min_monad_construct_error_move_destruct" (
          echo     ^<skipped/^> >> results.xml
        ) else if "!FILE!" == "min_monad_then" (
          echo     ^<skipped/^> >> results.xml
        ) else (
          echo FAILURE: Opcodes generated !LINE! exceeds 7
          echo     ^<failure message="Opcodes generated !LINE! exceeds 7"/^> >> results.xml
        )
      )
      echo     ^<system-out^> >> results.xml
      echo ^<^^![CDATA[ >> results.xml
      type !FILE!.msvc.S.test1.s >> results.xml
      echo ]]^> >> results.xml
      echo     ^</system-out^> >> results.xml
      echo   ^</testcase^> >> results.xml
    )
    echo.
  )
)
echo ^</testsuite^> >> results.xml
echo !MSVCLINE! >> msvc.csv
echo !CLANGLINE! >> msvc_clang.csv
