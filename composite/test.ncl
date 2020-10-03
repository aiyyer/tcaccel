begin


xorig = (/ (/3,2,1/), (/5,4,6/)/)

 opt = True

 x = xorig
 opt@title  = "Before sorting on rightmost dimension, increasing"
 write_matrix(x, "3I4", opt)

 ii_rgt = dim_pqsort_n(x,2,0)


 opt@title  = "After sorting on rightmost dimension, increasing"
 write_matrix(x, "3I4", opt)

 opt@title  = "Index vector"
 write_matrix(ii_rgt, "3I4", opt)
  
end