#include <oasis.h>

static unsigned add(unsigned lhs, unsigned rhs)
{
    return lhs + rhs;
}

int main(void)
{
    return (int)add(10u, 20u);
}
