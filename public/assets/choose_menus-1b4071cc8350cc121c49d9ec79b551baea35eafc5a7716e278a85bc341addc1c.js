$(document).ready(function(){if(0===window.performance.navigation.type);else if(1===window.performance.navigation.type)sessionStorage.clear();else{let a=sessionStorage.getItem("array_time"),s=sessionStorage.getItem("array_price"),i=JSON.parse(sessionStorage.getItem("menus"));$("#totalPrice").attr("price",s).html("\uffe5"+s),$("#totalTime").attr("time",a).html(a+"\u5206");for(var e=0,t=[];e<i.length;)i.forEach(function(a){if(0===e){(i=$("#selectedMenu").clone().css("display","block")).removeAttr("id");var s="selectedCheck"+a.value;t.push(s),i.attr("id","selectedCheck"+a.value),i.find("#selected_Name").html(a.nameKey),i.find("#selected_Price").html("\uffe5"+a.priceKey),i.find("#selected_Time").html(a.timeKey+"\u5206"),$("#selectedMenu").after(i)}else{var i;(i=$("#selectedMenu").clone().css("display","block")).removeAttr("id");s="selectedCheck"+a.value;i.attr("id","selectedCheck"+a.value),i.find("#selected_Name").html(a.nameKey),i.find("#selected_Price").html("\uffe5"+a.priceKey),i.find("#selected_Time").html(a.timeKey+"\u5206"),console.log(t.pop()),$(t.pop()).before(i),t.push(s)}}),e++}$(document).on("change","input:checkbox",function(){if(this.checked){var e=$("#selectedMenu").clone().css("display","block");e.removeAttr("id"),e.attr("id","selectedCheck"+$(this).val());var t=$(this).attr("data-name"),a=$(this).attr("data-price"),s=$(this).attr("data-time");e.find("#selected_Name").html(t),e.find("#selected_Price").html("\uffe5"+a),e.find("#selected_Time").html(s+"\u5206"),$("#selectedMenu").after(e)}else{$("#selectedCheck"+$(this).val()).remove()}var i=[],r=[],n=[],c=[];$('input[name="menus[]"]:checked').each(function(){var e=$(this).val(),t=$(this).attr("data-name"),s=parseInt($(this).attr("data-price")),l=parseInt($(this).attr("data-time")),o=$(this).clone();i.push(s),r.push(l),c.push(o),n.push({value:e,nameKey:t,priceKey:a,timeKey:l})});for(var l=0,o=0,m=i.length;o<m;o++)l+=i[o];var d=0;for(o=0,m=r.length;o<m;o++)d+=r[o];$("#totalPrice").attr("price",l).html("\uffe5"+l),$("#totalTime").attr("time",d).html(d+"\u5206"),console.log(d),console.log(l),console.log(c);var h=JSON.stringify(n);sessionStorage.setItem("array_time",d),sessionStorage.setItem("array_price",l),sessionStorage.setItem("menus",h),sessionStorage.setItem("clonedMenu",JSON.stringify(c))}),$(document).on("click","#submit-btn",function(){if(0===$('input[name="menus[]"]:checked').length)return alert("\u30e1\u30cb\u30e5\u30fc\u3092\u9078\u629e\u3057\u3066\u4e0b\u3055\u3044"),!1})});