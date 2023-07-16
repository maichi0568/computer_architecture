.eqv SEVENSEG_LEFT    0xFFFF0011    # Dia chi cua den led 7 doan trai  
.eqv SEVENSEG_RIGHT   0xFFFF0010    # Dia chi cua den led 7 doan phai  
.eqv KEY_CODE         0xFFFF0004    # Dia chi luu ma Ascii cua ky tu duoc nhap vao 
.eqv KEY_READY        0xFFFF0000    # Gia tri o dia chi nay bang 1 neu co phim moi duoc danh. Duoc tu dong xoa sau khi load word                                                      
.eqv DISPLAY_CODE     0xFFFF000C    # Dia chi de hien thi ky tu ra man hinh
.eqv DISPLAY_READY    0xFFFF0008    # Bang 1 neu man hinh san sang cho hien thi, tu dong xoa sau khi store word                              
.eqv MASK_CAUSE_KEYBOARD   0x0000034# Keyboard cause	
  
.data 
            bytehex     : .byte 0x3F,0x6,0x5B,0x4F,0x66,0x6D,0x7D,0x7,0x7F,0x6F #0->9 cua LED
            storestring : .space 1000  #bọ nho la 1000 byte de luu cac ky tu da doc
            enterstring : .asciiz "bo mon ky thuat may tinh" 
            mess: .asciiz "\nSo ky tu trong 1s :  "
            speed: .asciiz "\nToc do go tren giay:  "
            don_vi: .asciiz " time/char"
            numkeyright: .asciiz  "\nSo ky tu nhap dung la: "
            notification: .asciiz "\nBan co muon nhap lai tu dau khong? "
            total: .asciiz "\nThoi gian hoan thanh la: "

.text
            li   $k0,  KEY_CODE              
            li   $k1,  KEY_READY                    
            li   $s0,  DISPLAY_CODE              
            li   $s1,  DISPLAY_READY  

MAIN:       li $s4,0                #dung de dem toan bo so ky tu nhap vao
            li $s3,0                #dung de dem so vong lap 
            li $t4,10               #phuc vu cho viec hien thi led
            li $t5,250              #luu gia tri so vong lap. 
            li $t6,0                #bien dem so ky tu nhap duoc trong 1s
            li $t9,0        	     #moi lan nguoi dung nhap xong, thanh ghi t9 duoc gan thanh 1, de chuong trinh biet va goi thu tuc ASK_LOOP (hoi nguoi dung co muon nhap lai ko)
            li $s5,0                # so giay la 0ms
LOOP:          
WAIT_FOR_KEY:lw   $t1, 0($k1)        #Doc gia tri o KEY_READY neu co gia tri la 1 thi co ky tu moi duoc nhap vao, 0 neu khong co ky tu moi             
             beq  $t1, $zero,CK      #Neu khong doc duoc ky tu nao thi tiep tuc chu ky moi ma khong tao interrupt  
MAKE_INTER:  addi $t6,$t6,1          #tang bien dem ky tu nhap duoc trong 1s len 1
             teqi $t1, 1             #Tao ngat mem    
CK:          addi $s3, $s3, 1        #dem so chu ky trong s hien tai, duoc tra ve 0 sau moi 1s
             addi  $s5,$s5,4         #so giay la +4ms
             div $s3,$t5             #moi chu ky nghi 4ms nen neu du 250 chu ky tuc la du 1s
             mfhi $t7                #luu phan du cua phep chia tren
             bne $t7,0,SLEEP         #neu chua duoc 1s tiep tuc cho chuong trinh nghi 4ms            
#neu da duoc 1s thi nhay den nhan SETCOUNT de thuc hien in ra man hinh
SETCOUNT:   
            li $s3,0                #tai lap gia tri cua $t3 ve 0 de dem lai so vong lap cho cac lan tiep theo
            li $v0,4                #in ra console thong bao so ky tu nhap duoc trong 1s
            la $a0,mess
            syscall 
            nop
            li    $v0,1             #in ra so ky tu trong 1s
            add   $a0,$t6,$zero         
            syscall
            
DISPLAY_SPEED: 
        div $t6,$t4                  #lay so ky tu nhap duoc trong 1s chia cho 10
        mflo $t7                     #luu gia tri phan nguyen, gia tri nay se duoc luu o den LED ben trai
        la $s2,bytehex               #lay dia chi cua danh sach luu gia tri cua tung chu so den LED
        add $s2,$s2,$t7              
        lb $a0,0($s2)                #lay noi dung cho vao $a0           
        li   $t0,  SEVENSEG_LEFT     #lay dia chi hien thi den leg bay doan trai                   
        sb   $a0,  0($t0)            #gan gia tri can hien thi     

        mfhi $t7                     #luu gia tri phan du cua phep chia, gia tri nay se duoc in ra trong den LED ben phai
        la $s2,bytehex          
        add $s2,$s2,$t7
        lb $a0,0($s2)                         
        li   $t0,  SEVENSEG_RIGHT   # Lay dia chi hien thi den leg bay doan phai                  
        sb   $a0,  0($t0)           # gian gia tri can hien thi   
                             
        li    $t6,0             	#reset $t6 = 0
        beq $t9,1,ASK_LOOP 
SLEEP:  
        addi    $v0,$zero,32                   
        li      $a0,4                # sleep 4 ms         
        syscall         
        nop                     
        b       LOOP             	# Loop 
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# XU LY NGAT
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
.ktext  0x80000180                      #chuong trinh con chay sau khi interupt duoc goi.         
        mfc0  $t1, $13                  # cho biet nguyen nhan lam tham chieu dia chi bo nho khong hop
        li    $t2, MASK_CAUSE_KEYBOARD              
        and   $at, $t1,$t2              
        beq   $at,$t2, COUNTER_KETYBOARD              
        j    END_PROCESS 
         
COUNTER_KETYBOARD: 
READ_KEY:    lw   $t0, 0($k0)               #doc ky tu duoc nhap vao

WAIT_FOR_DIS:lw   $t2, 0($s1)               #doc gia tri tai dia chi DISPLAY_READY, neu gia tri la 1 thi hien thi ky tu nhap vao, nguoc tai tiep tuc cho            
             beq  $t2, $zero, WAIT_FOR_DIS  #tiep tuc cho  
                                       
SHOW_KEY:    sw $t0, 0($s0)                 #hien thi ky tu vua nhap tu ban phim tren man hinh MMIO
             la  $t7,storestring            #luu dia chi cua mang nhap vao thanh ghi t7
             add $t7,$t7,$s4            
             sb $t0,0($t7)		     #luu ky tu vua doc duoc vao mang
             addi $s4,$s4,1         	     #tang so ky tu nhap duoc them 1
             beq $t0,'\n',END               #neu ky tu nhap vao la ky tu xuong dong thi nhay den label end         
END_PROCESS:  
#---------------------------------------------------
#Tuy nhien, luu y rang, trong MARS, thanh ghi PC van chua dia chi cua lenh 
#ma ngat xay ra, tuc la lenh da thuc hien xong, chu khong chua dia chi cua 
#lenh ke tiep. Boi vay phi tu lap trinh de tang dia chi chua trong thanh ghi 
#epc bang cach su dung 2 lenh mfc0 (de doc thanh ghi trong bo dong xu ly
#C0) va mtc0 (de ghi gia tri vao thanh ghi trong bo dong xu ly C0) 
#---------------------------------------------------                                   i
NEXT_PC:    mfc0    $at, $14             	# $at <- Coproc0.$14 = Coproc0.epc              
            addi    $at, $at, 4         	# $at = $at + 4 (next instruction)              
            mtc0    $at, $14            	# Coproc0.$14 = Coproc0.epc <- $at  
RETURN:     eret             		        # tro ve len ke tiep cua chuong trinh chinh
                                  
END:        li $v0,11         
            li $a0,'\n'                	#in xuong dong
            syscall 
            
            li $t1,0                    	#i = 0
            li $t3,0                   	#bien dem so ky tu nhap dung
            li $t8,24                   	#luu $t8 la do dai xau "Bo mon ky thuat may tinh"
            slt $t7,$s4,$t8             	#kiem tra do dai xau da cho va xau nhap vao xau nao ngan hon thi duyet theo xau do
            bne $t7,1, COMPARE_STRING 
            add $t8,$0,$s4
            addi $t8,$t8,-1             	#ky tu cuoi cung nhap vao la '\n' khong can xet
             
COMPARE_STRING: la $t2,storestring
                add $t2,$t2,$t1     	        #lap qua cac ky tu
                lb $t5,0($t2)                  #lay ky tu duoc luu tru ra
                la $t4,enterstring
                add $t4,$t4,$t1
                lb $t6,0($t4)                  #lay ky tu thu $t1 trong enterstring luu vao $t6
                bne $t6,$t5,CONTINUE           
                addi $t3,$t3,1                 #hai ky tu dang xet giong nhau tang bien dem
                
CONTINUE:   addi $t1,$t1,1                     #i++
            beq $t1,$t8,PRINT                  #i = n
            j COMPARE_STRING        	        #tiep tuc check ki tu tiep theo 
            
PRINT:      
        li $v0, 4	
        la $a0, speed	
	syscall		# In xau speed
	
	mtc1 $s4, $f1		# $s4(integer) -> $f1(float): so luong phim da nhap
	mtc1 $s5, $f2		# $s5(integer) -> $f2(float): so luong time 
	div.s $f12, $f2, $f1	# Toc do trung binh (so chu ky ngat/1 ky tu)
	li $v0, 2
	syscall
	
	li $v0, 4		
	la $a0, don_vi		
	syscall			# In message don_vi
           
        li $v0,4            
        la $a0,numkeyright  
        syscall
        li $v0,1
        add $a0,$0,$t3
        syscall  
        
        li $v0, 4	
        la $a0, total	# In thong bao tong thoi gian
	syscall	
	
	li $v0, 1
	mul $a0, $s4, $s5 #thoi gian=tong ky tu* tong thoi gian
	syscall
            
        li $t9,1            
        li $t4,10                   	#gan lai gia tri cho t4 = 10 de phuc vu cho viec hien thi den leg
        add $t6,$0,$t3 
        b DISPLAY_SPEED 
            
ASK_LOOP:  li $v0, 50              	        #tao thong bao hoi nguoi dung 
    	   la $a0, notification            
    	   syscall
    	   beq $a0,0,MAIN                  	#neu nguoi dung chon yes quay lai MAIN
    	   nop
    	   li $v0,10
    	   syscall
