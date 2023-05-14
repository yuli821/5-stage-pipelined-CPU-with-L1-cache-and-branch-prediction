package branch_predictor;
class lc_branch;

    bit [1:0] BHT [];

    function new(int index_size);
        this.BHT = new[1 << index_size];
        for(int i = 0 ; i < (1<<index_size) ; i++) begin
            BHT[i] = 2'b00;
        end
    endfunction

    function update_array(bit [8:0] idx, bit direction);//need to modify [8:0] for trying different index
        if(BHT[idx] === 2'b00) begin
            if(direction) BHT[idx] = 2'b01;
        end
        else if (BHT[idx] === 2'b01) begin
            if(direction) BHT[idx] = 2'b10;
            else          BHT[idx] = 2'b00;
        end
        else if (BHT[idx] === 2'b10) begin
            if(direction) BHT[idx] = 2'b11;
            else          BHT[idx] = 2'b01;
        end
        else if (BHT[idx] === 2'b11) begin
            if(!direction) BHT[idx] = 2'b10;
        end
    endfunction

    function bit [1:0] get_pred_dir(bit [8:0] idx, bit [6:0] opcode);//need to modify [8:0] for trying different index
        bit [1:0] dir;
        if((opcode === 7'b1101111) || (opcode === 7'b1100111)) begin
            dir = 2'b11;
        end
        else begin
            dir = BHT[idx];
        end
        return dir;
    endfunction

endclass

class gl_branch;

    bit [1:0] BHT [];
    bit [8:0] hist [];//need to modify [8:0] for trying different index

    function new(int index_size);
        this.BHT = new[1 << index_size];
        this.hist = new[1 << index_size];
        for(int i = 0 ; i < (1<<index_size) ; i++) begin
            BHT[i] = 2'b00;
            hist[i] = {9{1'b0}};//need to modify 9 for trying different index
        end
    endfunction

    function update_array(bit [8:0] index, bit direction);//need to modify [8:0] for trying different index
        bit [8:0] idx = index ^ hist[index];//need to modify [8:0] for trying different index
        hist[index] = {hist[index][7:0],direction};
        if(BHT[idx] === 2'b00) begin
            if(direction) BHT[idx] = 2'b01;
        end
        else if (BHT[idx] === 2'b01) begin
            if(direction) BHT[idx] = 2'b10;
            else          BHT[idx] = 2'b00;
        end
        else if (BHT[idx] === 2'b10) begin
            if(direction) BHT[idx] = 2'b11;
            else          BHT[idx] = 2'b01;
        end
        else if (BHT[idx] === 2'b11) begin
            if(!direction) BHT[idx] = 2'b10;
        end
    endfunction

    function bit [1:0] get_pred_dir(bit [8:0] index, bit [6:0] opcode);//need to modify [8:0] for trying different index
        bit [1:0] dir;
        bit [8:0] idx = index ^ hist[index];
        if((opcode === 7'b1101111) || (opcode === 7'b1100111)) begin
            dir = 2'b11;
        end
        else begin
            dir = BHT[idx];
        end
        return dir;
    endfunction

endclass

class tn_branch;

    bit [1:0] curr_state;

    function new();
        curr_state = 2'b01;
    endfunction

    function update_state(bit ex_mem_lc_dir, bit ex_mem_gl_dir, bit ex_mem_br_en);
        bit lc_correct = ~(ex_mem_lc_dir ^ ex_mem_br_en);
        bit gl_correct = ~(ex_mem_gl_dir ^ ex_mem_br_en);
        if(curr_state == 2'b00) begin
            if(lc_correct & ~gl_correct) curr_state = 2'b01;
            else if(~lc_correct & gl_correct) curr_state = 2'b10;
        end
        else if (curr_state == 2'b01) begin
            if(~lc_correct & gl_correct) curr_state = 2'b00;
        end
        else if (curr_state == 2'b10) begin
            if(~lc_correct & gl_correct) curr_state = 2'b11;
            else if (lc_correct & ~gl_correct) curr_state = 2'b00;
        end
        else if (curr_state == 2'b11) begin
            if(lc_correct & ~gl_correct) curr_state = 2'b10;
        end
    endfunction

    function bit get_dir(bit lc_dir, bit gl_dir);
        if(curr_state == 2'b00) return lc_dir;
        else if (curr_state == 2'b01) return lc_dir;
        else if (curr_state == 2'b10) return gl_dir;
        else if (curr_state == 2'b11) return gl_dir;
    endfunction

endclass

class plru;
    plru left;
    plru right;
    bit value;
    int l;
    function new(int level);
        value = 1'b0;
        l = level;
        if (level > 1) begin
            left = new(level-1);
            right = new(level-1);
        end
        else begin
            left = null;
            right = null;
        end
    endfunction

    function update(int access_index);
        bit dir = access_index[l-1];
        value = dir;
        if(~dir) begin  //left child
            if(left)  left.update(access_index);
        end
        else begin     //right hild
            if(right) right.update(access_index);
        end
    endfunction

    function int out();
        int _out = 0;
        if(~value) begin  //last access is left child
            if(right) _out = right.out();
        end
        else begin        //last access is right child
            if(left) _out = left.out();
        end
        _out[l-1] = ~value;
        return _out;
    endfunction
endclass

class RAS;

bit [31:0] stack [];
int TOS;
int depth;
bit ret;

function new(int depth_idx);
    stack = new[1 << depth_idx];
    depth = depth_idx;
    TOS = 0;
    ret = 1'b0;
    for(int i = 0 ; i < (1 << depth_idx)-1 ; i++) begin
        stack[i] <= 32'b0;
    end
endfunction

function push(bit [6:0] opcode, bit [4:0] rd, bit [4:0] rs1, bit [31:0] pc);
    if(opcode == 7'b1100111) begin
        if((rd == 5'b00001) && (rd != rs1)) begin
            if(TOS < ((1 << depth) - 1)) begin
                stack[TOS] = pc + 4;
                TOS = TOS + 1;
            end
        end
    end
endfunction

function bit [31:0] pop(bit [6:0] opcode, bit [4:0] rd, bit [4:0] rs1);
    ret = 1'b0;
    if(opcode == 7'b1100111) begin
        if((rs1 == 5'b00001) && (rd != rs1)) begin
            ret = 1'b1;
            if(TOS > 0) begin
                TOS <= TOS - 1;
                return stack[TOS-1];
            end
            else begin
                TOS <= 0;
                return stack[0];
            end
        end
    end
endfunction

function bit get_ret();
    return ret;
endfunction

function int get_TOS();
    return TOS;
endfunction

endclass

endpackage

